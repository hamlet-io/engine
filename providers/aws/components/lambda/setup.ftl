[#ftl]
[#macro aws_lambda_cf_generationcontract_application occurrence ]
    [@addDefaultGenerationContract subsets=["prologue", "template", "config"] /]
[/#macro]

[#macro aws_lambda_cf_setup_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#list occurrence.Occurrences as fn]
        [@internalProcessFunction fn /]
    [/#list]
[/#macro]

[#-- Rename once we switch to the context model for processing --]
[#macro aws_functionxx_cf_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=["prologue", "template", "config"] /]
        [#return]
    [/#if]

    [@internalProcessFunction occurrence /]
[/#macro]

[#macro internalProcessFunction fn ]

    [#local core = fn.Core ]
    [#local solution = fn.Configuration.Solution ]
    [#local resources = fn.State.Resources ]

    [#local deploymentType = solution.DeploymentType ]

    [#local fnId = resources["function"].Id ]
    [#local fnName = resources["function"].Name ]

    [#local fnLgId = resources["lg"].Id ]
    [#local fnLgName = resources["lg"].Name ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(fn, [ "OpsData", "AppData", "Encryption" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]

    [#local cmkKeyId = baselineComponentIds["Encryption" ]]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]

    [#local vpcAccess = solution.VPCAccess ]
    [#if vpcAccess ]
        [#local networkLink = getOccurrenceNetwork(fn).Link!{} ]

        [#local networkLinkTarget = getLinkTarget(fn, networkLink ) ]
        [#if ! networkLinkTarget?has_content ]
            [@fatal message="Network could not be found" context=networkLink /]
            [#return]
        [/#if]

        [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#local networkResources = networkLinkTarget.State.Resources ]

        [#local vpcId = networkResources["vpc"].Id ]
        [#local vpc = getExistingReference(vpcId)]
    [/#if]

    [#local fragment = getOccurrenceFragmentBase(fn) ]

    [#local contextLinks = getLinkTargets(fn) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(fn, contextLinks, baselineLinks),
            "Environment" : {},
            "S3Bucket" : getRegistryEndPoint("lambda", fn),
            "S3Key" :
                formatRelativePath(
                    getRegistryPrefix("lambda", fn),
                    productName,
                    getOccurrenceBuildScopeExtension(fn),
                    getOccurrenceBuildUnit(fn),
                    getOccurrenceBuildReference(fn),
                    "lambda.zip"
                ),
            "Links" : contextLinks,
            "BaselineLinks" : baselineLinks,
            "DefaultCoreVariables" : true,
            "DefaultEnvironmentVariables" : true,
            "DefaultLinkVariables" : true,
            "DefaultBaselineVariables" : true,
            "Policy" : standardPolicies(fn, baselineComponentIds),
            "ManagedPolicy" : [],
            "CodeHash" : solution.FixedCodeVersion.CodeHash
        }
    ]

    [#if deploymentSubsetRequired("lambda", true)]
        [#list _context.Links as linkName,linkTarget]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]
            [#local linkTargetRoles = linkTarget.State.Roles ]
            [#local linkDirection = linkTarget.Direction ]
            [#local linkRole = linkTarget.Role]

            [#switch linkDirection ]
                [#case "inbound" ]
                    [#switch linkRole ]
                        [#case "invoke" ]
                            [#switch linkTargetCore.Type]
                                [#case USERPOOL_COMPONENT_TYPE ]
                                [#case LAMBDA_FUNCTION_COMPONENT_TYPE ]
                                [#case APIGATEWAY_COMPONENT_TYPE ]
                                [#case TOPIC_COMPONENT_TYPE]
                                [#case S3_COMPONENT_TYPE ]
                                    [@createLambdaPermission
                                        id=formatLambdaPermissionId(fn, "link", linkName)
                                        targetId=fnId
                                        source=linkTargetRoles.Inbound["invoke"]
                                    /]
                                    [#break]

                            [/#switch]
                            [#break]

                    [/#switch]
                    [#break]
                [#case "outbound" ]
                    [#switch linkRole ]
                        [#case "event" ]
                            [#switch linkTargetCore.Type ]
                                [#case SQS_COMPONENT_TYPE ]
                                    [#if linkTargetAttributes["ARN"]?has_content ]
                                        [@createLambdaEventSource
                                            id=formatLambdaEventSourceId(fn, "link", linkName)
                                            targetId=fnId
                                            source=linkTargetAttributes["ARN"]
                                            batchSize=1
                                        /]
                                    [/#if]
                                    [#break]
                                [#case TOPIC_COMPONENT_TYPE ]
                                    [#if linkTargetAttributes["ARN"]?has_content ]
                                        [@createSNSSubscription
                                            id=formatDependentSNSSubscriptionId(fn, "link", linkName)
                                            topicId=linkTargetResources["topic"].Id
                                            endpoint=getReference(fnId, ARN_ATTRIBUTE_TYPE)
                                            protocol="lambda"
                                        /]
                                    [/#if]
                                    [#break]
                            [/#switch]
                            [#break]
                    [/#switch]
                    [#break]
            [/#switch]
        [/#list]
    [/#if]

    [#-- Add in fragment specifics including override of defaults --]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#-- clear all environment variables for EDGE deployments --]
    [#if deploymentType == "EDGE" ]
            [#assign _context += {
            "DefaultEnvironment" : {},
            "Environment" : {}
        }]
    [/#if]

    [#local finalEnvironment = getFinalEnvironment(fn, _context, solution.Environment) ]
    [#local finalAsFileEnvironment = getFinalEnvironment(fn, _context, solution.Environment + {"AsFile" : false}) ]
    [#assign _context += finalEnvironment ]

    [#local roleId = formatDependentRoleId(fnId)]
    [#local managedPolicies =
        (vpcAccess)?then(
            ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"],
            ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
        ) +
        (solution.Tracing.Configured && solution.Tracing.Enabled)?then(
            ["arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"],
            []
        ) +
        _context.ManagedPolicy ]

    [#local linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

    [#-- Ensure policies are ignored as dependencies unless created as part of this template --]
    [#local policyId = ""]
    [#local linkPolicyId = ""]

    [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]

        [#-- Create a role under which the function will run and attach required policies --]
        [#-- The role is mandatory though there may be no policies attached to it --]
        [@createRole
            id=roleId
            trustedServices=[
                "lambda.amazonaws.com"
            ] +
            (deploymentType == "EDGE")?then(
                [
                    "edgelambda.amazonaws.com"
                ],
                []
            )
            managedArns=managedPolicies

        /]

        [#if _context.Policy?has_content]
            [#local policyId = formatDependentPolicyId(fnId)]
            [@createPolicy
                id=policyId
                name=_context.Name
                statements=_context.Policy
                roles=roleId
            /]
        [/#if]

        [#if linkPolicies?has_content]
            [#local linkPolicyId = formatDependentPolicyId(fnId, "links")]
            [@createPolicy
                id=linkPolicyId
                name="links"
                statements=linkPolicies
                roles=roleId
            /]
        [/#if]
    [/#if]

    [#if deploymentType == "REGIONAL" &&
            solution.PredefineLogGroup &&
            deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(fnLgId) ]

        [@createLogGroup
            id=fnLgId
            name=fnLgName /]
    [/#if]


    [#if isPresent(solution.FixedCodeVersion) ]
        [#local versionId = resources["version"].Id  ]
        [#local versionResourceId = resources["version"].ResourceId ]
        [#local codeHash = _context.CodeHash!solution.FixedCodeVersion.CodeHash ]

        [#if !(core.Version?has_content)]
            [@fatal
                message="A version must be defined for Fixed Code Version deployments"
                context=core
            /]
        [/#if]

        [#if deploymentSubsetRequired("lambda", true)]
            [@createLambdaVersion
                id=versionResourceId
                targetId=fnId
                codeHash=_context.CodeHash!""
                outputId=versionId
            /]
        [/#if]
    [/#if]

    [#if deploymentSubsetRequired("lambda", true)]
        [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
        [#if vpcAccess ]
            [@createDependentSecurityGroup
                resourceId=fnId
                resourceName=formatName("lambda", fnName)
                occurrence=fn
                vpcId=vpcId/]
        [/#if]

        [#if solution.PredefineLogGroup && deploymentType == "REGIONAL"]
            [#list resources.logMetrics!{} as logMetricName,logMetric ]

                [@createLogMetric
                    id=logMetric.Id
                    name=logMetric.Name
                    logGroup=logMetric.LogGroupName
                    filter=logFilters[logMetric.LogFilter].Pattern
                    namespace=getResourceMetricNamespace(logMetric.Type)
                    value=1
                    dependencies=logMetric.LogGroupId
                /]

            [/#list]
        [/#if]

        [@createLambdaFunction
            id=fnId
            settings=_context +
                {
                    "Handler" : solution.Handler,
                    "RunTime" : solution.RunTime,
                    "MemorySize" : solution.Memory,
                    "Timeout" : solution.Timeout,
                    "Encrypted" : solution.Encrypted,
                    "KMSKeyId" : cmkKeyId,
                    "Name" : fnName,
                    "Description" : fnName,
                    "Tracing" : solution.Tracing,
                    "ReservedExecutions" : solution.ReservedExecutions
                }
            roleId=roleId
            securityGroupIds=
                (vpcAccess)?then(
                    formatDependentSecurityGroupId(fnId),
                    []
                )
            subnetIds=
                (vpcAccess)?then(
                    getSubnets(core.Tier, networkResources, "", false),
                    []
                )
            dependencies=
                [roleId, policyId, linkPolicyId] +
                valueIfTrue([fnLgId], solution.PredefineLogGroup, [])
        /]

        [#if deploymentType == "EDGE" ]

            [#if !isPresent(solution.FixedCodeVersion) ]
                [@fatal
                    message="EDGE based deployments must be deployed as Fixed code version deployments"
                    context=_context
                    detail="Lambda@Edge deployments are based on a snapshot of lambda code and a specific codeontap version is requried "
                /]
            [/#if]

            [@createLambdaPermission
                id=formatLambdaPermissionId(fn, "replication")
                action="lambda:GetFunction"
                targetId=versionResourceId
                source={
                    "Principal" : "replicator.lambda.amazonaws.com"
                }
                sourceId=scheduleRuleId
                dependencies=scheduleRuleId
            /]
        [/#if]

        [#list solution.Schedules?values as schedule ]

            [#local scheduleRuleId = formatEventRuleId(fn, "schedule", schedule.Id) ]

            [#local targetParameters = {
                "Arn" : getReference(fnId, ARN_ATTRIBUTE_TYPE),
                "Id" : fnId,
                "Input" : getJSON(schedule.Input?has_content?then(schedule.Input,{ "path" : schedule.InputPath }))
            }]

            [@createScheduleEventRule
                id=scheduleRuleId
                enabled=schedule.Enabled
                scheduleExpression=schedule.Expression
                targetParameters=targetParameters
                dependencies=fnId
            /]

            [@createLambdaPermission
                id=formatLambdaPermissionId(fn, "schedule", schedule.Id)
                targetId=fnId
                sourcePrincipal="events.amazonaws.com"
                sourceId=scheduleRuleId
                dependencies=scheduleRuleId
            /]
        [/#list]

        [#list solution.LogWatchers as logWatcherName,logwatcher ]

            [#local logFilter = logFilters[logwatcher.LogFilter].Pattern ]

            [#list logwatcher.Links as logWatcherLinkName,logWatcherLink ]
                [#local logWatcherLinkTarget = getLinkTarget(fn, logWatcherLink) ]

                [#if !logWatcherLinkTarget?has_content]
                    [#continue]
                [/#if]

                [#local roleSource = logWatcherLinkTarget.State.Roles.Inbound["logwatch"]]

                [#list asArray(roleSource.LogGroupIds) as logGroupId ]

                    [#local logGroupArn = getExistingReference(logGroupId, ARN_ATTRIBUTE_TYPE)]

                    [#if logGroupArn?has_content ]

                        [@createLambdaPermission
                            id=formatLambdaPermissionId(fn, "logwatch", logWatcherLink.Id, logGroupId?index)
                            targetId=fnId
                            source={
                                "Principal" : roleSource.Principal,
                                "SourceArn" : logGroupArn
                            }
                            dependencies=fnId
                        /]

                        [@createLogSubscription
                            id=formatDependentLogSubscriptionId(fnId, logWatcherLink.Id, logGroupId?index)
                            logGroupName=getExistingReference(logGroupId)
                            filter=logFilter
                            destination=fnId
                            dependencies=fnId
                        /]

                    [/#if]
                [/#list]
            [/#list]
        [/#list]

        [#list solution.Alerts?values as alert ]

            [#local monitoredResources = getMonitoredResources(core.Id, resources, alert.Resource)]
            [#list monitoredResources as name,monitoredResource ]

                [#switch alert.Comparison ]
                    [#case "Threshold" ]
                        [@createAlarm
                            id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                            severity=alert.Severity
                            resourceName=core.FullName
                            alertName=alert.Name
                            actions=getCWAlertActions(fn, solution.Profiles.Alert, alert.Severity )
                            metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                            namespace=getResourceMetricNamespace(monitoredResource.Type, alert.Namespace)
                            description=alert.Description!alert.Name
                            threshold=alert.Threshold
                            statistic=alert.Statistic
                            evaluationPeriods=alert.Periods
                            period=alert.Time
                            operator=alert.Operator
                            reportOK=alert.ReportOk
                            unit=alert.Unit
                            missingData=alert.MissingData
                            dimensions=getResourceMetricDimensions(monitoredResource, resources)
                        /]
                    [#break]
                [/#switch]
            [/#list]
        [/#list]
    [/#if]
    [#if solution.Environment.AsFile && deploymentSubsetRequired("config", false)]
        [@addToDefaultJsonOutput content=finalAsFileEnvironment.Environment /]
    [/#if]
    [#if deploymentSubsetRequired("prologue", false)]
        [#-- Copy any asFiles needed by the task --]
        [#local asFiles = getAsFileSettings(fn.Configuration.Settings.Product) ]
        [#if asFiles?has_content]
            [@debug message="Asfiles" context=asFiles enabled=false /]
            [@addToDefaultBashScriptOutput
                content=
                    findAsFilesScript("filesToSync", asFiles) +
                    syncFilesToBucketScript(
                        "filesToSync",
                        regionId,
                        operationsBucket,
                        getOccurrenceSettingValue(fn, "SETTINGS_PREFIX")
                    ) /]
        [/#if]
        [#if solution.Environment.AsFile]
            [@addToDefaultBashScriptOutput
                content=
                    getLocalFileScript(
                        "configFiles",
                        "$\{CONFIG}",
                        "config_" + commandLineOptions.Run.Id + ".json"
                    ) +
                    syncFilesToBucketScript(
                        "configFiles",
                        regionId,
                        operationsBucket,
                        formatRelativePath(
                            getOccurrenceSettingValue(fn, "SETTINGS_PREFIX"),
                            "config"
                        )
                    ) /]
        [/#if]
        [@addToDefaultBashScriptOutput
            content=(vpcAccess)?then(
                [
                    "case $\{STACK_OPERATION} in",
                    "  delete)"
                ] +
                [
                    "# Release ENIs",
                    "info \"Releasing ENIs ... \"",
                    "release_enis" +
                    " \"" + region + "\" " +
                    " \"" + fnName + "\" || return $?"

                ] +
                [
                    "       ;;",
                    "       esac"
                ],
                []
            )
        /]
    [/#if]
[/#macro]

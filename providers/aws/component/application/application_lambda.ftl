[#ftl]
[#macro aws_lambda_cf_application occurrence ]
    [@cfDebug listMode occurrence false  /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["prologue", "template", "config"])
        /]
        [#return]
    [/#if]

    [#local lambdaCore = occurrence.Core ]
    [#local lambdaSolution = occurrence.Configuration.Solution ]

    [#local deploymentType = lambdaSolution.DeploymentType ]

    [#list occurrence.Occurrences as fn]
        [#local core = fn.Core ]
        [#local solution = fn.Configuration.Solution ]
        [#local resources = fn.State.Resources ]

        [#local fnId = resources["function"].Id ]
        [#local fnName = resources["function"].Name ]

        [#local fnLgId = resources["lg"].Id ]
        [#local fnLgName = resources["lg"].Name ]

        [#local vpcAccess = solution.VPCAccess ]
        [#if vpcAccess ]
            [#local networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

            [#local networkLinkTarget = getLinkTarget(fn, networkLink ) ]
            [#if ! networkLinkTarget?has_content ]
                [@cfException listMode "Network could not be found" networkLink /]
                [#return]
            [/#if]

            [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
            [#local networkResources = networkLinkTarget.State.Resources ]

            [#local vpcId = networkResources["vpc"].Id ]
            [#local vpc = getExistingReference(vpcId)]
        [/#if]

        [#local fragment = getOccurrenceFragmentBase(fn) ]

        [#local contextLinks = getLinkTargets(fn) ]
        [#local _context =
            {
                "Id" : fragment,
                "Name" : fragment,
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "DefaultEnvironment" : defaultEnvironment(fn, contextLinks),
                "Environment" : {},
                "S3Bucket" : getRegistryEndPoint("lambda", occurrence),
                "S3Key" :
                    formatRelativePath(
                        getRegistryPrefix("lambda", occurrence) + productName,
                        getOccurrenceBuildUnit(occurrence),
                        getOccurrenceBuildReference(occurrence),
                        "lambda.zip"
                    ),
                "Links" : contextLinks,
                "DefaultCoreVariables" : true,
                "DefaultEnvironmentVariables" : true,
                "DefaultLinkVariables" : true,
                "Policy" : standardPolicies(fn),
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
                                        [@createLambdaPermission
                                            mode=listMode
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
                                                mode=listMode
                                                id=formatLambdaEventSourceId(fn, "link", linkName)
                                                targetId=fnId
                                                source=linkTargetAttributes["ARN"]
                                                batchSize=1
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
        [#local fragmentListMode = "model"]
        [#local fragmentId = formatFragmentId(_context)]
        [#include fragmentList?ensure_starts_with("/")]

        [#-- clear all environment variables for EDGE deployments --]
        [#if deploymentType == "EDGE" ]
                [#local _context += {
                "DefaultEnvironment" : {},
                "Environment" : {}
            }]
        [/#if]

        [#local finalEnvironment = getFinalEnvironment(fn, _context, solution.Environment) ]
        [#local finalAsFileEnvironment = getFinalEnvironment(fn, _context, solution.Environment + {"AsFile" : false}) ]
        [#local _context += finalEnvironment ]

        [#local roleId = formatDependentRoleId(fnId)]
        [#local managedPolicies =
            (vpcAccess)?then(
                ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"],
                ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
            ) +
            _context.ManagedPolicy ]

        [#local linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

        [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]

            [#-- Create a role under which the function will run and attach required policies --]
            [#-- The role is mandatory though there may be no policies attached to it --]
            [@createRole
                mode=listMode
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
                    mode=listMode
                    id=policyId
                    name=_context.Name
                    statements=_context.Policy
                    roles=roleId
                /]
            [/#if]

            [#if linkPolicies?has_content]
                [#local policyId = formatDependentPolicyId(fnId, "links")]
                [@createPolicy
                    mode=listMode
                    id=policyId
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
                mode=listMode
                id=fnLgId
                name=fnLgName /]
        [/#if]

        [#if deploymentSubsetRequired("lambda", true)]
            [#if isPresent(solution.FixedCodeVersion) ]
                [#local versionId = resources["version"].Id  ]
                [#local codeHash = _context.CodeHash!solution.FixedCodeVersion.CodeHash ]

                [#if !(core.Version?has_content)]
                    [@cfException
                        mode=listMode
                        description="A version must be defined for Fixed Code Version deployments"
                        context=core
                    /]
                [/#if]

                [@createLambdaVersion
                    mode=listMode
                    id=versionId
                    targetId=fnId
                    codeHash=_context.CodeHash!""
                    dependencies=fnId
                    /]
            [/#if]

            [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
            [#if vpcAccess ]
                [@createDependentSecurityGroup
                    mode=listMode
                    resourceId=fnId
                    resourceName=formatName("lambda", fnName)
                    occurrence=occurrence
                    vpcId=vpcId/]
            [/#if]

            [#if solution.PredefineLogGroup && deploymentType == "REGIONAL"]
                [#list resources.logMetrics!{} as logMetricName,logMetric ]

                    [@createLogMetric
                        mode=listMode
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
                mode=listMode
                id=fnId
                settings=_context +
                    {
                        "Handler" : solution.Handler,
                        "RunTime" : solution.RunTime,
                        "MemorySize" : solution.Memory,
                        "Timeout" : solution.Timeout,
                        "UseSegmentKey" : solution.UseSegmentKey,
                        "Name" : fnName,
                        "Description" : fnName
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
                    [roleId] +
                    valueIfTrue([fnLgId], solution.PredefineLogGroup, [])
            /]

            [#if deploymentType == "EDGE" ]

                [#if !isPresent(solution.FixedCodeVersion) ]
                    [@cfException
                        mode=listMode
                        description="EDGE based deployments must be deployed as Fixed code version deployments"
                        context=_context
                        detail="Lambda@Edge deployments are based on a snapshot of lambda code and a specific codeontap version is requried "
                    /]
                [/#if]

                [@createLambdaPermission
                    mode=listMode
                    id=formatLambdaPermissionId(fn, "replication")
                    action="lambda:GetFunction"
                    targetId=versionId
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
                    mode=listMode
                    id=scheduleRuleId
                    enabled=schedule.Enabled
                    scheduleExpression=schedule.Expression
                    targetParameters=targetParameters
                    dependencies=fnId
                /]

                [@createLambdaPermission
                    mode=listMode
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
                    [#local logWatcherLinkTarget = getLinkTarget(occurrence, logWatcherLink) ]

                    [#if !logWatcherLinkTarget?has_content]
                        [#continue]
                    [/#if]

                    [#local roleSource = logWatcherLinkTarget.State.Roles.Inbound["logwatch"]]

                    [#list asArray(roleSource.LogGroupIds) as logGroupId ]

                        [#local logGroupArn = getExistingReference(logGroupId, ARN_ATTRIBUTE_TYPE)]

                        [#if logGroupArn?has_content ]

                            [@createLambdaPermission
                                mode=listMode
                                id=formatLambdaPermissionId(fn, "logwatch", logWatcherLink.Id, logGroupId?index)
                                targetId=fnId
                                source={
                                    "Principal" : roleSource.Principal,
                                    "SourceArn" : logGroupArn
                                }
                                dependencies=fnId
                            /]

                            [@createLogSubscription
                                mode=listMode
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

                [#local monitoredResources = getMonitoredResources(resources, alert.Resource)]
                [#list monitoredResources as name,monitoredResource ]

                    [#switch alert.Comparison ]
                        [#case "Threshold" ]
                            [@createCountAlarm
                                mode=listMode
                                id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                severity=alert.Severity
                                resourceName=core.FullName
                                alertName=alert.Name
                                actions=[
                                    getReference(formatSegmentSNSTopicId())
                                ]
                                metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                                namespace=getResourceMetricNamespace(monitoredResource.Type)
                                description=alert.Description!alert.Name
                                threshold=alert.Threshold
                                statistic=alert.Statistic
                                evaluationPeriods=alert.Periods
                                period=alert.Time
                                operator=alert.Operator
                                reportOK=alert.ReportOk
                                missingData=alert.MissingData
                                dimensions=getResourceMetricDimensions(monitoredResource, resources)
                                dependencies=monitoredResource.Id
                            /]
                        [#break]
                    [/#switch]
                [/#list]
            [/#list]

            [#-- Pick any extra macros in the fragment --]
            [#local fragmentListMode = listMode]
            [#include fragmentList?ensure_starts_with("/")]
        [/#if]
        [#if solution.Environment.AsFile && deploymentSubsetRequired("config", false)]
            [@cfConfig
                mode=listMode
                content=finalAsFileEnvironment.Environment
            /]
        [/#if]
        [#if deploymentSubsetRequired("prologue", false)]
            [#-- Copy any asFiles needed by the task --]
            [#local asFiles = getAsFileSettings(fn.Configuration.Settings.Product) ]
            [#if asFiles?has_content]
                [@cfDebug listMode asFiles false /]
                [@cfScript
                    mode=listMode
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
                [@cfScript
                    mode=listMode
                    content=
                        getLocalFileScript(
                            "configFiles",
                            "$\{CONFIG}",
                            "config_" + runId + ".json"
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
            [@cfScript
                mode=listMode
                content=(vpcAccess)?then(
                    [
                        "case $\{STACK_OPERATION} in",
                        "  delete)"
                    ] +
                    [
                        "# Release ENIs",
                        "info \"Realising ENIs ... \"",
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
    [/#list]
[/#macro]

[#-- Lambda --]

[#if componentType = "lambda"]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence ]

        [@cfDebug listMode occurrence false  /]

        [#assign lambdaCore = occurrence.Core ]
        [#assign lambdaSolution = occurrence.Configuration.Solution ]

        [#assign deploymentType = lambdaSolution.DeploymentType ]

        [#list occurrence.Occurrences as fn]
            [#assign core = fn.Core ]
            [#assign solution = fn.Configuration.Solution ]
            [#assign resources = fn.State.Resources ]

            [#assign fnId = resources["function"].Id ]
            [#assign fnName = resources["function"].Name ]

            [#assign fnLgId = resources["lg"].Id ]
            [#assign fnLgName = resources["lg"].Name ]

            [#assign fragment =
                contentIfContent(solution.Fragment, getComponentId(core.Component)) ]

            [#assign contextLinks = getLinkTargets(fn) ]
            [#assign _context =
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

                    [#assign linkTargetCore = linkTarget.Core ]
                    [#assign linkTargetConfiguration = linkTarget.Configuration ]
                    [#assign linkTargetResources = linkTarget.State.Resources ]
                    [#assign linkTargetAttributes = linkTarget.State.Attributes ]
                    [#assign linkTargetRoles = linkTarget.State.Roles ]
                    [#assign linkDirection = linkTarget.Direction ]
                    [#assign linkRole = linkTarget.Role]

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
            [#assign fragmentListMode = "model"]
            [#assign fragmentId = formatFragmentId(_context)]
            [#assign containerId = fragmentId]
            [#include fragmentList?ensure_starts_with("/")]

            [#-- clear all environment variables for EDGE deployments --]
            [#if deploymentType == "EDGE" ]
                    [#assign _context += {
                    "DefaultEnvironment" : {},
                    "Environment" : {}
                }]
            [/#if]

            [#assign finalEnvironment = getFinalEnvironment(fn, _context, solution.Environment) ]
            [#assign finalAsFileEnvironment = getFinalEnvironment(fn, _context, solution.Environment + {"AsFile" : false}) ]
            [#assign _context += finalEnvironment ]

            [#assign roleId = formatDependentRoleId(fnId)]
            [#assign managedPolicies =
                (vpc?has_content && solution.VPCAccess)?then(
                    ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"],
                    ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
                ) +
                _context.ManagedPolicy ]

            [#assign linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

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
                    [#assign policyId = formatDependentPolicyId(fnId)]
                    [@createPolicy
                        mode=listMode
                        id=policyId
                        name=_context.Name
                        statements=_context.Policy
                        roles=roleId
                    /]
                [/#if]

                [#if linkPolicies?has_content]
                    [#assign policyId = formatDependentPolicyId(fnId, "links")]
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

                [#list solution.LogMetrics as logMetricName,logMetric ]

                    [#assign logMetricResource = resources[("lgMetric" + logMetricName)] ]
                    [#assign logFilter = logFilters[logMetric.LogFilter].Pattern ]

                    [@createLogMetric
                        mode=listMode
                        id=logMetricResource.Id
                        name=logMetricResource.Name
                        logGroup=fnLgName
                        filter=logFilter
                        namespace=getResourceMetricNamespace(logMetricResource)
                        value=1
                        dependencies=fnLgId
                    /]

                [/#list]
            [/#if]

            [#if deploymentSubsetRequired("lambda", true)]
                [#if isPresent(solution.FixedCodeVersion) ]
                    [#assign versionId = resources["version"].Id  ]
                    [#assign codeHash = _context.CodeHash!solution.FixedCodeVersion.CodeHash ]

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
                [#if vpc?has_content && solution.VPCAccess]
                    [@createDependentSecurityGroup
                        mode=listMode
                        tier=tier
                        component=component
                        resourceId=fnId
                        resourceName=formatName("lambda", fnName) /]
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
                        (vpc?has_content && solution.VPCAccess)?then(
                            formatDependentSecurityGroupId(fnId),
                            []
                        )
                    subnetIds=
                        (vpc?has_content && solution.VPCAccess)?then(
                            getSubnets(core.Tier, false),
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

                    [#assign scheduleRuleId = formatEventRuleId(fn, "schedule", schedule.Id) ]

                    [@createScheduleEventRule
                        mode=listMode
                        id=scheduleRuleId
                        targetId=fnId
                        enabled=schedule.Enabled
                        scheduleExpression=schedule.Expression
                        input=schedule.Input
                        path=schedule.InputPath
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

                    [#assign logFilter = logFilters[logwatcher.LogFilter].Pattern ]

                    [#list logwatcher.Links as logWatcherLinkName,logWatcherLink ]
                        [#assign logWatcherLinkTarget = getLinkTarget(occurrence, logWatcherLink) ]

                        [#if !logWatcherLinkTarget?has_content]
                            [#continue]
                        [/#if]

                        [#assign roleSource = logWatcherLinkTarget.State.Roles.Inbound["logwatch"]]

                        [#list asArray(roleSource.LogGroupIds) as logGroupId ]

                            [#assign logGroupArn = getExistingReference(logGroupId, ARN_ATTRIBUTE_TYPE)]

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

                    [#assign monitoredResources = getMonitoredResources(resources, alert.Resource)]
                    [#list monitoredResources as name,monitoredResource ]

                        [#switch alert.Comparison ]
                            [#case "Threshold" ]
                                [@createCountAlarm
                                    mode=listMode
                                    id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                    name=alert.Severity?upper_case + "-" + monitoredResource.Name!core.ShortFullName + "-" + alert.Name
                                    actions=[
                                        getReference(formatSegmentSNSTopicId())
                                    ]
                                    metric=getMetricName(alert.Metric.Name, monitoredResource.Type, fn)
                                    namespace=getResourceMetricNamespace(monitoredResource)
                                    description=alert.Description!alert.Name
                                    threshold=alert.Threshold
                                    statistic=alert.Statistic
                                    evaluationPeriods=alert.Periods
                                    period=alert.Time
                                    operator=alert.Operator
                                    reportOK=alert.ReportOk
                                    missingData=alert.MissingData
                                    dimensions=getResourceMetricDimensions(monitoredResource)
                                    dependencies=monitoredResource.Id
                                /]
                            [#break]
                        [/#switch]
                    [/#list]
                [/#list]

                [#-- Pick any extra macros in the fragment --]
                [#assign fragmentListMode = listMode]
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
                [#assign asFiles = getAsFileSettings(fn.Configuration.Settings.Product) ]
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
                    content=(vpc?has_content && solution.VPCAccess)?then(
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
    [/#list]
[/#if]

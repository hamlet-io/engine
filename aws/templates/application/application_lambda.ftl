[#-- Lambda --]

[#if componentType = "lambda"]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence ]

        [@cfDebug listMode occurrence false  /]

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
            [#assign context =
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
                    "ManagedPolicy" : []
                }
            ]

            [#if deploymentSubsetRequired("lambda", true)]
                [#list context.Links as linkName,linkTarget]

                    [#assign linkTargetCore = linkTarget.Core ]
                    [#assign linkTargetConfiguration = linkTarget.Configuration ]
                    [#assign linkTargetResources = linkTarget.State.Resources ]
                    [#assign linkTargetAttributes = linkTarget.State.Attributes ]
                    [#assign linkTargetRoles = linkTarget.State.Roles ]
                    [#assign linkDirection = linkTarget.Direction ]

                    [#switch linkTargetCore.Type]
                        [#case USERPOOL_COMPONENT_TYPE ]
                        [#case LAMBDA_FUNCTION_COMPONENT_TYPE ]
                        [#case APIGATEWAY_COMPONENT_TYPE ]
                        
                            [#if linkTargetResources[(linkTargetCore.Type)].Deployed &&
                                    (linkDirection == "inbound" )]
                                [#if linkTargetRoles.Inbound["invoke"]?has_content ]
                                    [@createLambdaPermission
                                        mode=listMode
                                        id=formatLambdaPermissionId(fn, "link", linkName)
                                        targetId=fnId
                                        source=linkTargetRoles.Inbound["invoke"]
                                    /]
                                [/#if]

                                [#if linkTargetRoles.Inbound["logwatch"]?has_content ]
                                    [@createLambdaPermission
                                        mode=listMode
                                        id=formatLambdaPermissionId(fn, "logwatch", linkName)
                                        targetId=fnId
                                        source=linkTargetRoles.Inbound["logwatch"]
                                    /]
                                [/#if]
                            [/#if]
                            [#break]

                        [#-- Event sources --]
                        [#case SQS_COMPONENT_TYPE]
                            [#if linkTarget.Role == "event" &&
                                linkTargetAttributes["ARN"]?has_content]
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
                [/#list]
            [/#if]

            [#-- Add in fragment specifics including override of defaults --]
            [#assign fragmentListMode = "model"]
            [#assign fragmentId = formatFragmentId(context)]
            [#assign containerId = fragmentId]
            [#include fragmentList?ensure_starts_with("/")]

            [#assign finalEnvironment = getFinalEnvironment(fn, context, solution.EnvironmentAsFile) ]
            [#assign finalAsFileEnvironment = getFinalEnvironment(fn, context, false) ]
            [#assign context += finalEnvironment ]

            [#assign roleId = formatDependentRoleId(fnId)]
            [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]
                [#assign managedPolicies =
                        (vpc?has_content && solution.VPCAccess)?then(
                            ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"],
                            ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
                        ) +
                        context.ManagedPolicy ]

                [#-- Create a role under which the function will run and attach required policies --]
                [#-- The role is mandatory though there may be no policies attached to it --]
                [@createRole
                    mode=listMode
                    id=roleId
                    trustedServices=["lambda.amazonaws.com"]
                    managedArns=managedPolicies

                /]

                [#if context.Policy?has_content]
                    [#assign policyId = formatDependentPolicyId(fnId)]
                    [@createPolicy
                        mode=listMode
                        id=policyId
                        name=context.Name
                        statements=context.Policy
                        roles=roleId
                    /]
                [/#if]

                [#assign linkPolicies = getLinkTargetsOutboundRoles(context.Links) ]

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

            [#if solution.PredefineLogGroup &&
                  deploymentSubsetRequired("lg", true) &&
                  isPartOfCurrentDeploymentUnit(fnLgId) ]
                [@createLogGroup
                    mode=listMode
                    id=fnLgId
                    name=fnLgName /]
            [/#if]

            [#if deploymentSubsetRequired("lambda", true)]
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
                    settings=context +
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

                    [#if deploymentSubsetRequired("lambda", true)]
                        [#switch logwatcher.Type ]
                            [#case "Metric" ]
                                [@createLogMetric
                                    mode=listMode
                                    id=formatDependentLogMetricId(fnId, logwatcher.Id)
                                    name=formatName(logWatcherName, fnName)
                                    logGroup=fnLgName
                                    filter=logwatcher.LogPattern
                                    namespace=formatProductRelativePath()
                                    value=1
                                    dependencies=fnId
                                /]
                            [#break]

                            [#case "Subscription" ]
                                [#list logwatcher.Links as logWatchLinkName,logWatcherLink ]
                                    [#assign logWatcherLinkTarget = getLinkTarget(occurrence, logWatcherLink) ]
                                    [#assign logWatcherLinkTargetCore = logWatcherLinkTarget.Core ]
                                    [#assign logWatcherLinkTargetAttributes = logWatcherLinkTarget.State.Attributes ]
                                    [#switch logWatcherLinkTargetCore.Type]

                                        [#case LAMBDA_FUNCTION_COMPONENT_TYPE]
                                            [@createLogSubscription 
                                                mode=listMode
                                                id=formatDependentLogSubscriptionId(fnId, logwatcher.Id)
                                                logGroup=fnLgName
                                                filter=logwatcher.LogPattern
                                                destination=logWatcherLinkTargetAttributes["ARN"]
                                                /]
                                            [#break]
                                    [/#switch]
                                [/#list]
                            [#break]
                        [/#switch]
                    [/#if]
                [/#list]

                [#list solution.Alerts?values as alert ]

                    [#assign dimensions=[] ]
                    [#assign metricName = alert.Metric.Name ]

                    [#switch alert.Metric.Type]
                        [#case "LogFilter" ]
                            [#-- TODO: Ideally We should use dimensions for filtering but they aren't available on Log Metrics --]
                            [#-- feature requst has been reaised... --]
                            [#-- Instead we name the logMetric with the function name and will use that --]
                            [#assign metricName = formatName(alert.Metric.Name, fnName) ]
                        [#break]
                    [/#switch]

                    [#switch alert.Comparison ]
                        [#case "Threshold" ]
                            [@createCountAlarm
                                mode=listMode
                                id=formatDependentAlarmId(fnId, alert.Id)
                                name=alert.Severity?upper_case + "-" + fnName + "-" + alert.Name
                                actions=[
                                    getReference(formatSegmentSNSTopicId())
                                ]
                                metric=metricName
                                namespace=alert.Namespace?has_content?then(
                                                alert.Namespace,
                                                formatProductRelativePath()
                                                )
                                description=alert.Description?has_content?then(
                                                alert.Description,
                                                alert.Name
                                                )
                                threshold=alert.Threshold
                                statistic=alert.Statistic
                                evaluationPeriods=alert.Periods
                                period=alert.Time
                                operator=alert.Operator
                                reportOK=alert.ReportOk
                                missingData=alert.MissingData
                                dimensions=dimensions
                                dependencies=fnId
                            /]
                        [#break]
                    [/#switch]
                [/#list]

                [#-- Pick any extra macros in the fragment --]
                [#assign fragmentListMode = listMode]
                [#include fragmentList?ensure_starts_with("/")]
            [/#if]
            [#if solution.EnvironmentAsFile && deploymentSubsetRequired("config", false)]
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
                [#if solution.EnvironmentAsFile]
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

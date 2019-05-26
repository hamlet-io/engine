[#ftl]
[#macro solution_mobilenotifier tier component]
    [#-- Mobile Notifier --]
    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]

        [#assign successSampleRate = solution.SuccessSampleRate ]
        [#assign encryptionScheme = solution.Credentials.EncryptionScheme?ensure_ends_with(":")]

        [#assign deployedPlatformAppArns = []]

        [#assign roleId = resources["role"].Id]

        [#assign platformAppAttributesCommand = "attributesPlatformApp" ]
        [#assign platformAppDeleteCommand = "deletePlatformApp" ]

        [#assign hasPlatformApp = false]

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources ]

            [#assign successSampleRate = solution.SuccessSampleRate!successSampleRate ]
            [#assign encryptionScheme = solution.EncryptionScheme!encryptionScheme]

            [#assign platformAppId = resources["platformapplication"].Id]
            [#assign platformAppName = resources["platformapplication"].Name ]
            [#assign engine = resources["platformapplication"].Engine ]

            [#assign lgId= resources["lg"].Id ]
            [#assign lgName = resources["lg"].Name ]
            [#assign lgFailureId = resources["lgfailure"].Id ]
            [#assign lgFailureName = resources["lgfailure"].Name ]

            [#assign platformAppAttributesCliId = formatId( platformAppId, "attributes" )]

            [#assign platformArn = getExistingReference( platformAppId, ARN_ATTRIBUTE_TYPE) ]

            [#if platformArn?has_content ]
                [#assign deployedPlatformAppArns += [ platformArn ] ]
            [/#if]

            [#assign isPlatformApp = false]

            [#assign platformAppCreateCli = {} ]
            [#assign platformAppUpdateCli = {} ]

            [#assign platformAppPrincipal =
                getOccurrenceSettingValue(occurrence, ["MobileNotifier", core.SubComponent.Name + "_Principal"], true) ]

            [#assign platformAppCredential =
                getOccurrenceSettingValue(occurrence, ["MobileNotifier", core.SubComponent.Name + "_Credential"], true) ]

            [#assign engineFamily = "" ]

            [#switch engine ]
                [#case "APNS" ]
                [#case "APNS_SANDBOX" ]
                    [#assign engineFamily = "APPLE" ]
                    [#break]

                [#case "GCM" ]
                    [#assign engineFamily = "GOOGLE" ]
                    [#break]

                [#case MOBILENOTIFIER_SMS_ENGINE ]
                    [#assign engineFamily = MOBILENOTIFIER_SMS_ENGINE ]
                    [#break]

                [#default]
                    [@cfException
                        mode=listMode
                        description="Unkown Engine"
                        context=component
                        detail=engine /]
            [/#switch]

            [#switch engineFamily ]
                [#case "APPLE" ]
                    [#assign isPlatformApp = true]
                    [#assign hasPlatformApp = true]
                    [#if !platformAppCredential?has_content || !platformAppPrincipal?has_content ]
                        [@cfException
                            mode=listMode
                            description="Missing Credentials - Requires both Credential and Principal"
                            context=component
                            detail={
                                "Credential" : platformAppCredential!"",
                                "Principal" : platformAppPrincipal!""
                            } /]
                    [/#if]
                    [#break]

                [#case "GOOGLE" ]
                    [#assign isPlatformApp = true]
                    [#assign hasPlatformApp = true]
                    [#if !platformAppPrincipal?has_content ]
                        [@cfException
                            mode=listMode
                            description="Missing Credential - Requires Principal"
                            context=component
                            detail={
                                "Principal" : platformAppPrincipal!""
                            } /]
                    [/#if]
                    [#break]
            [/#switch]

            [#if deploymentSubsetRequired("lg", true) &&
                isPartOfCurrentDeploymentUnit(lgId)]

                [#if engine != MOBILENOTIFIER_SMS_ENGINE]
                    [@createLogGroup
                        mode=listMode
                        id=lgId
                        name=lgName /]

                    [@createLogGroup
                        mode=listMode
                        id=lgFailureId
                        name=lgFailureName /]
                [/#if]

            [/#if]

            [#if deploymentSubsetRequired(MOBILENOTIFIER_COMPONENT_TYPE, true)]

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

                [#list solution.Alerts?values as alert ]

                    [#assign monitoredResources = getMonitoredResources(resources, alert.Resource)]
                    [#list monitoredResources as name,monitoredResource ]

                        [@cfDebug listMode monitoredResource false /]

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
            [/#if]

            [#if isPlatformApp ]
                [#if deploymentSubsetRequired("cli", false ) ]

                    [#assign platformAppAttributes =
                        getSNSPlatformAppAttributes(
                            roleId,
                            successSampleRate
                            platformAppCredential,
                            platformAppPrincipal )]

                    [@cfCli
                        mode=listMode
                        id=platformAppAttributesCliId
                        command=platformAppAttributesCommand
                        content=platformAppAttributes
                    /]

                [/#if]

                [#if deploymentSubsetRequired( "epilogue", false) ]

                    [@cfScript
                        mode=listMode
                        content=
                            [
                                "# Platform: " + core.SubComponent.Name,
                                "case $\{STACK_OPERATION} in",
                                "  create|update)",
                                "       # Get cli config file",
                                "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?",
                                "       info \"Deploying SNS PlatformApp: " + core.SubComponent.Name + "\"",
                                "       platform_app_arn=\"$(deploy_sns_platformapp" +
                                "       \"" + region + "\" " +
                                "       \"" + platformAppName + "\" " +
                                "       \"" + platformArn + "\" " +
                                "       \"" + encryptionScheme + "\" " +
                                "       \"" + engine + "\" " +
                                "       \"$\{tmpdir}/cli-" +
                                        platformAppAttributesCliId + "-" + platformAppAttributesCommand + ".json\")\""
                            ] +
                            pseudoStackOutputScript(
                                "SNS Platform App",
                                {
                                    formatId(platformAppId, "arn") : "$\{platform_app_arn}",
                                    platformAppId : core.Name
                                },
                                core.SubComponent.Id
                            ) +
                            [
                                "       ;;",
                                "  delete)",
                                "       # Delete SNS Platform Application",
                                "       info \"Deleting SNS Platform App " + core.SubComponent.Name + "\" ",
                                "       delete_sns_platformapp" +
                                "       \"" + region + "\" " +
                                "       \"" + platformArn + "\" "
                                "   ;;",
                                "   esac"
                            ]
                    /]
                [/#if]
            [/#if]
        [/#list]

        [#if hasPlatformApp ]
            [#if deploymentSubsetRequired( "prologue", false) ]
                [@cfScript
                    mode=listMode
                    content=
                        [
                            "# Mobile Notifier Cleanup",
                            "case $\{STACK_OPERATION} in",
                            "  create|update)",
                            "       info \"Cleaning up platforms that have been removed from config\"",
                            "       cleanup_sns_platformapps " +
                            "       \"" + region + "\" " +
                            "       \"" + platformAppName + "\" " +
                            "       '" + getJSON(deployedPlatformAppArns, false) + "' || return $?",
                            "       ;;",
                            "       esac"
                        ]

                /]
            [/#if]

            [#if deploymentSubsetRequired("iam", true)
                && isPartOfCurrentDeploymentUnit(roleId)]

                [@createRole
                    mode=listMode
                    id=roleId
                    trustedServices=["sns.amazonaws.com" ]
                    policies=
                        [
                            getPolicyDocument(
                                    cwLogsProducePermission() +
                                    cwLogsConfigurePermission(),
                                "logging")
                        ]
                /]
            [/#if]
        [/#if]
    [/#list]
[/#macro]
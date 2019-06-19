[#ftl]
[#macro aws_mobilenotifier_cf_solution occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["prologue", "template", "epilogue", "cli"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]

    [#local successSampleRate = solution.SuccessSampleRate ]
    [#local encryptionScheme = solution.Credentials.EncryptionScheme?ensure_ends_with(":")]

    [#local deployedPlatformAppArns = []]

    [#local roleId = resources["role"].Id]

    [#local platformAppAttributesCommand = "attributesPlatformApp" ]
    [#local platformAppDeleteCommand = "deletePlatformApp" ]

    [#local hasPlatformApp = false]

    [#list occurrence.Occurrences![] as subOccurrence]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]
        [#local resources = subOccurrence.State.Resources ]

        [#local successSampleRate = solution.SuccessSampleRate!successSampleRate ]
        [#local encryptionScheme = solution.EncryptionScheme!encryptionScheme]

        [#local platformAppId = resources["platformapplication"].Id]
        [#local platformAppName = resources["platformapplication"].Name ]
        [#local engine = resources["platformapplication"].Engine ]

        [#local lgId= resources["lg"].Id ]
        [#local lgName = resources["lg"].Name ]
        [#local lgFailureId = resources["lgfailure"].Id ]
        [#local lgFailureName = resources["lgfailure"].Name ]

        [#local platformAppAttributesCliId = formatId( platformAppId, "attributes" )]

        [#local platformArn = getExistingReference( platformAppId, ARN_ATTRIBUTE_TYPE) ]

        [#if platformArn?has_content ]
            [#local deployedPlatformAppArns += [ platformArn ] ]
        [/#if]

        [#local isPlatformApp = false]

        [#local platformAppCreateCli = {} ]
        [#local platformAppUpdateCli = {} ]

        [#local platformAppPrincipal =
            getOccurrenceSettingValue(occurrence, ["MobileNotifier", core.SubComponent.Name + "_Principal"], true) ]

        [#local platformAppCredential =
            getOccurrenceSettingValue(occurrence, ["MobileNotifier", core.SubComponent.Name + "_Credential"], true) ]

        [#local engineFamily = "" ]

        [#switch engine ]
            [#case "APNS" ]
            [#case "APNS_SANDBOX" ]
                [#local engineFamily = "APPLE" ]
                [#break]

            [#case "GCM" ]
                [#local engineFamily = "GOOGLE" ]
                [#break]

            [#case MOBILENOTIFIER_SMS_ENGINE ]
                [#local engineFamily = MOBILENOTIFIER_SMS_ENGINE ]
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
                [#local isPlatformApp = true]
                [#local hasPlatformApp = true]
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
                [#local isPlatformApp = true]
                [#local hasPlatformApp = true]
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

                [#local monitoredResources = getMonitoredResources(resources, alert.Resource)]
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

                [#local platformAppAttributes =
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
[/#macro]
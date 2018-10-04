[#-- Mobile Notifier --]

[#if componentType == MOBILENOTIFIER_COMPONENT_TYPE  ]

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

                [#list solution.LogMetrics as logMetricName,logMetric ]

                    [#assign logFilter = logFilters[logMetric.LogFilter].Pattern ]

                    [@createLogMetric
                        mode=listMode
                        id=formatDependentLogMetricId(platformAppId, logMetric.Id)
                        name=formatName(logMetricName, platformAppName)
                        logGroup=lgName
                        filter=logFilter
                        namespace=formatProductRelativePath()
                        value=1
                        dependencies=lgId
                    /]

                    [@createLogMetric
                        mode=listMode
                        id=formatDependentLogMetricId(platformAppId, logMetric.Id, "failure")
                        name=formatName(logMetricName, platformAppName, "failure")
                        logGroup=lgFailureName
                        filter=logFilter
                        namespace=formatProductRelativePath()
                        value=1
                        dependencies=lgFailureId
                    /]
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
                                        platformAppAttributesCliId + "-" + platformAppAttributesCommand + ".json\")\"",
                                "       pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-" + core.SubComponent.Id + "-pseudo-stack.json\" ",
                                "       create_pseudo_stack" + " " +
                                "       \"SNS Platform App\"" + " " +
                                "       \"$\{pseudo_stack_file}\"" + " " +
                                "       \"" + platformAppId + "Xarn\" \"$\{platform_app_arn}\"" +
                                "       \"" + platformAppId + "\" \"" + core.Name + "\" || return $?",
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
[/#if]
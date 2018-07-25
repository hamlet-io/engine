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

        [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]
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

        [#assign platformAppCreateCommand = "createPlatformApp" ]
        [#assign platformAppUpdateCommand = "updatePlatformApp" ]
        [#assign platformAppDeleteCommand = "deletePlatformApp" ]

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources ]

            [#assign successSampleRate = solution.SuccessSampleRate!successSampleRate ] 
            [#assign encryptionScheme = solution.EncryptionScheme!encryptionScheme]

            [#assign platformAppId = resources["platformapplication"].Id]
            [#assign platformAppName = resources["platformapplication"].Name ]
            [#assign platformAppCreateCliId = formatId( platformAppId, "create" )]
            [#assign platformAppUpdateCliId = formatId( platformAppId, "update" )]

            [#assign platformArn = getExistingReference( platformAppId, ARN_ATTRIBUTE_TYPE) ] 
            
            [#if platformArn?has_content ]
                [#assign deployedPlatformAppArns += [ platformArn ] ]
            [/#if]
            
            [#assign isPlatformApp = false]

            [#assign engine = solution.Engine!core.SubComponent.Name ]

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
                
                [#case "SMS" ]
                    [#assign engineFamily = "SMS" ]
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
            
            [#if isPlatformApp ]
                [#if deploymentSubsetRequired("cli", false ) ]

                    [#assign platformAppCreateCli = 
                        getSNSPlatformAppCreateCli( 
                            platformAppName, 
                            engine, 
                            roleId,
                            successSampleRate, 
                            platformAppCredential,
                            platformAppPrincipal )]

                    [#assign platformAppUpdateCli = 
                        getSNSPlatformAppAttributes(
                            roleId, 
                            successSampleRate 
                            platformAppCredential,
                            platformAppPrincipal )]

                    [@cfCli 
                        mode=listMode
                        id=platformAppCreateCliId
                        command=platformAppCreateCommand
                        content=platformAppCreateCli
                    /]


                    [@cfCli 
                        mode=listMode
                        id=platformAppUpdateCliId
                        command=platformAppUpdateCommand
                        content=platformAppUpdateCli
                    /]
                [/#if]

                [#if deploymentSubsetRequired( "epilogue", false) ]
                    [@cfScript
                        mode=listMode
                        content= 
                            [
                                "# Platform: " + core.SubComponent.Id,
                                "case $\{STACK_OPERATION} in",
                                "  create|update)",
                                "       # Get cli config file",
                                "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                                "       # Apply CLI level updates to Application Platform",
                                "       info \"Applying cli level configurtion\""
                            ] +
                            (getExistingReference(platformAppId)?has_content)?then(
                                [
                                    "       deploy_sns_platformapp" +
                                    "       \"" + region + "\" " + 
                                    "       \"update\" " +
                                    "       \"" + getExistingReference(platformAppId) + "\" " + 
                                    "       \"" + encryptionScheme + "\" " +
                                    "       \"$\{tmpdir}/cli-" + 
                                            platformAppUpdateCliId + "-" + platformAppUpdateCommand + ".json\"",
                                    "    ;;",
                                    "  delete)",
                                    "       # Delete SNS Platform Application",
                                    "       info \"Deleting SNS Platform App " + getExistingReference(platformAppId) + "\" ",
                                    "       delete_sns_platformapp" +
                                    "       \"" + region + "\" " + 
                                    "       \"" + getExistingReference(platformAppId) + "\" "
                                ],
                                [
                                    "       platform_app_arn=$( deploy_sns_platformapp" +
                                    "       \"" + region + "\" " + 
                                    "       \"create\" " +
                                    "       \"" + platformAppName + "\" " + 
                                    "       \"" + encryptionScheme + "\" " +
                                    "       \"$\{tmpdir}/cli-" + 
                                            platformAppCreateCliId + "-" + platformAppCreateCommand + ".json\")",
                                    "       info \"Created $\{platform_app_arn}\" ",
                                    "       pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-" + core.SubComponent.Id + "-pseudo-stack.json\" ",
                                    "       create_pseudo_stack" + " " +
                                    "       \"SNS Platform Application\" " +
                                    "       \"$\{pseudo_stack_file}\"" + " " +
                                    "       \"" + platformAppId + "Xarn\" \"$\{platform_app_arn}\" || return $?"
                                ]
                            ) +
                            [
                                "   ;;",
                                "   esac"
                            ]
                    /]
                [/#if]
            [/#if]
        [/#list]

        
        [#if deploymentSubsetRequired( "prologue", false) ]
            [@cfScript
                mode=listMode
                content= 
                    deployedPlatformAppArns?has_content?then(
                        [
                            "# Mobile Notifier Cleanup",
                            "case $\{STACK_OPERATION} in",
                            "  create|update)",
                            "       info \"Cleanig up platforms that have been removed from config\"",
                            "       cleanup_sns_platformapps " + 
                            "       \"" + region + "\" " + 
                            "       \"" + platformAppName + "\" " + 
                            "       \"" + getJSON(deployedPlatformAppArns, true) + "\" || return $?",
                            "       ;;",
                            "       esac"   
                        ],
                        []
                    )
            /]
        [/#if]

    [/#list]
[/#if]
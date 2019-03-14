[#-- MobileApp --]
[#if componentType == MOBILEAPP_COMPONENT_TYPE]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        [#assign links = solution.Links ]

        [#assign mobileAppId = resources["mobileapp"].Id]

        [#if deploymentSubsetRequired("prologue", false)]
            [#-- Copy any asFiles needed by the task --]
            [#assign asFiles = getAsFileSettings(occurrence.Configuration.Settings.Product) ]
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
                            getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX")
                        ) /]
            [/#if]
        [/#if]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)"
                ] +    
                pseudoStackOutputScript(
                    "Mobile App",
                    { mobileAppId : mobileAppId }
                ) +
                [            
                    "       ;;",
                    "       esac"
                ]
            /]
        [/#if]
    [/#list]
[/#if]

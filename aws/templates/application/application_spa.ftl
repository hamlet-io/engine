[#-- SPA --]

[#if componentType = "spa"]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign settings = occurrence.Configuration.Settings ]

        [#assign containerId =
            solution.Container?has_content?then(
                solution.Container,
                getComponentId(component)
            ) ]
        [#assign context =
            {
                "Id" : containerId,
                "Name" : containerId,
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "DefaultEnvironment" : defaultEnvironment(occurrence),
                "Environment" : {},
                "Links" : getLinkTargets(occurrence),
                "DefaultCoreVariables" : false,
                "DefaultEnvironmentVariables" : false,
                "DefaultLinkVariables" : false
            }
        ]

        [#-- Add in container specifics including override of defaults --]
        [#assign containerListMode = "model"]
        [#assign containerId = formatContainerFragmentId(occurrence, context)]
        [#include containerList?ensure_starts_with("/")]

        [#assign context += getFinalEnvironment(occurrence, context) ]

        [#if deploymentSubsetRequired("config", false)]
            [@cfConfig
                mode=listMode
                content=context.Environment
            /]
        [/#if]
        [#if deploymentSubsetRequired("prologue", false)]
            [@cfScript
                mode=listMode
                content=
                    getBuildScript(
                        "spaFiles",
                        regionId,
                        "spa",
                        productName,
                        occurrence,
                        "spa.zip"
                    ) +
                    syncFilesToBucketScript(
                        "spaFiles",
                        regionId,
                        operationsBucket,
                        formatRelativePath(
                            getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                            "spa"
                        )
                    ) +
                    getLocalFileScript(
                        "configFiles",
                        "$\{CONFIG}",
                        "config.json"
                    ) +
                    syncFilesToBucketScript(
                        "configFiles",
                        regionId,
                        operationsBucket,
                        formatRelativePath(
                            getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                            "config"
                        )
                    ) /]
        [/#if]
    [/#list]
[/#if]

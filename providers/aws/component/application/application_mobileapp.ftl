[#ftl]
[#macro aws_mobileapp_cf_application occurrence ]
    [@cfDebug listMode occurrence false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["prologue", "config"])
        /]
        [#return]
    [/#if]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#local mobileAppId = resources["mobileapp"].Id]
    [#local configFilePath = resources["mobileapp"].ConfigFilePath ]
    [#local configFileName = resources["mobileapp"].ConfigFileName ]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : true,
            "DefaultLinkVariables" : false
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#local fragmentListMode = "model"]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local finalAsFileEnvironment = getFinalEnvironment(occurrence, _context, { "Json" : { "Include" : { "Sensitive" : false }}}) ]

    [#if deploymentSubsetRequired("config", false)]
        [@cfConfig
            mode=listMode
            content=finalAsFileEnvironment.Environment
        /]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [#-- Copy any asFiles needed by the task --]
        [#local asFiles = getAsFileSettings(occurrence.Configuration.Settings.Product) ]
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

        [@cfScript
            mode=listMode
            content=
                getLocalFileScript(
                    "configFiles",
                    "$\{CONFIG}",
                    configFileName
                ) +
                syncFilesToBucketScript(
                    "configFiles",
                    regionId,
                    operationsBucket,
                    configFilePath
                ) /]
    [/#if]
[/#macro]

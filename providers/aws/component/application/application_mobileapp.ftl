[#ftl]
[#macro aws_mobileapp_cf_application occurrence ]
    [@cfDebug listMode occurrence false /]

    [#assign core = occurrence.Core ]
    [#assign solution = occurrence.Configuration.Solution ]
    [#assign resources = occurrence.State.Resources ]

    [#assign mobileAppId = resources["mobileapp"].Id]
    [#assign configFilePath = resources["mobileapp"].ConfigFilePath ]
    [#assign configFileName = resources["mobileapp"].ConfigFileName ]

    [#assign fragment = getOccurrenceFragmentBase(occurrence) ]

    [#assign contextLinks = getLinkTargets(occurrence) ]
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
    [#assign fragmentListMode = "model"]
    [#assign fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#assign finalAsFileEnvironment = getFinalEnvironment(occurrence, _context, { "Json" : { "Include" : { "Sensitive" : false }}}) ]

    [#if deploymentSubsetRequired("config", false)]
        [@cfConfig
            mode=listMode
            content=finalAsFileEnvironment.Environment
        /]
    [/#if]

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

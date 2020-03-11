[#ftl]
[#macro aws_mobileapp_cf_generationcontract_application occurrence ]
    [@addDefaultGenerationContract subsets=["prologue", "config"] /]
[/#macro]

[#macro aws_mobileapp_cf_setup_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local attributes = occurrence.State.Attributes ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData", "AppData" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]

    [#local mobileAppId = resources["mobileapp"].Id]
    [#local configFilePath = resources["mobileapp"].ConfigFilePath ]
    [#local configFileName = resources["mobileapp"].ConfigFileName ]

    [#local codeSrcBucket = getRegistryEndPoint("scripts", occurrence)]
    [#local codeSrcPrefix = formatRelativePath(
                                getRegistryPrefix("scripts", occurrence),
                                    productName,
                                    getOccurrenceBuildScopeExtension(occurrence),
                                    getOccurrenceBuildUnit(occurrence),
                                    getOccurrenceBuildReference(occurrence))]

    [#local buildConfig =
        {
            "RUN_ID"            : commandLineOptions.Run.Id,
            "CODE_SRC_BUCKET"   : codeSrcBucket,
            "CODE_SRC_PREFIX"   : codeSrcPrefix,
            "APP_BUILD_FORMATS" : solution.BuildFormats?join(","),
            "BUILD_REFERENCE"   : getOccurrenceBuildReference(occurrence)
        } +
        attributes +
        defaultEnvironment(occurrence, {}, baselineLinks)
    ]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks, baselineLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "BaselineLinks" : baselineLinks,
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : true,
            "DefaultLinkVariables" : false,
            "DefaultBaselineVariables" : true
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local finalEnvironment = getFinalEnvironment(
            occurrence,
            _context,
            {
                "Json" : {
                    "Include" : {
                        "Sensitive" : false
                    }
                }
            }
    )]

    [#if deploymentSubsetRequired("config", false)]
        [@addToDefaultJsonOutput
            content={
                "BuildConfig" : buildConfig,
                "AppConfig" : finalEnvironment.Environment
            }
        /]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [#-- Copy any asFiles needed by the task --]
        [#local asFiles = getAsFileSettings(occurrence.Configuration.Settings.Product) ]
        [#if asFiles?has_content]
            [@debug message="Asfiles" context=asFiles enabled=false /]
            [@addToDefaultBashScriptOutput
                content=
                    findAsFilesScript("filesToSync", asFiles) +
                    syncFilesToBucketScript(
                        "filesToSync",
                        regionId,
                        operationsBucket,
                        getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX")
                    ) /]
        [/#if]

        [@addToDefaultBashScriptOutput
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

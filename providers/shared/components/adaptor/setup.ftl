[#ftl]
[#macro shared_adaptor_cf_generationcontract_application occurrence ]
    [@addDefaultGenerationContract subsets=["prologue", "config", "epilogue" ] /]
[/#macro]

[#macro shared_adaptor_cf_setup_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local attributes = occurrence.State.Attributes ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData", "AppData" ] )]

    [#local codeSrcBucket = getRegistryEndPoint("scripts", occurrence)]
    [#local codeSrcPrefix = formatRelativePath(
                                getRegistryPrefix("scripts", occurrence),
                                    productName,
                                    getOccurrenceBuildScopeExtension(occurrence),
                                    getOccurrenceBuildUnit(occurrence),
                                    getOccurrenceBuildReference(occurrence))]

    [#local buildSettings = occurrence.Configuration.Settings.Build ]
    [#local buildRegistry = buildSettings["BUILD_FORMATS"].Value[0] ]

    [#local asFiles = getAsFileSettings(occurrence.Configuration.Settings.Product) ]

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
            "ContextSettings" : {},
            "Links" : contextLinks,
            "BaselineLinks" : baselineLinks,
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : true,
            "DefaultLinkVariables" : false,
            "DefaultBaselineVariables" : false
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local EnvironmentSettings =
        {
            "Json" : {
                "Escaped" : false
            }
        }
    ]

    [#local finalEnvironment = getFinalEnvironment(occurrence, _context, EnvironmentSettings) ]
    [#if deploymentSubsetRequired("config", false)]
        [@addToDefaultJsonOutput
            content=finalEnvironment.Environment
        /]
    [/#if]

    [#if deploymentSubsetRequired("epilogue", false) ]
        [@addToDefaultBashScriptOutput
            content=
                getBuildScript(
                    "src_zip",
                    regionId,
                    buildRegistry,
                    productName,
                    occurrence,
                    buildRegistry + ".zip"
                ) +
                [
                    "addToArray src \"$\{tmpdir}/src/\"",
                    "unzip \"$\{src_zip}\" -d \"$\{src}\""
                ] +
                asFiles?has_content?then(
                     findAsFilesScript("settingsFiles", asFiles),
                     []
                ) +
                getLocalFileScript(
                    "config",
                    "$\{CONFIG}",
                    configFileName
                )
            section="1-Start"
        /]
    [/#if]
[/#macro]

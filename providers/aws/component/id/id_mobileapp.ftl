[#-- Resources --]
[#assign COT_MOBILEAPP_RESOURCE_TYPE = "mobileapp"]

[#macro aws_mobileapp_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(COT_MOBILEAPP_RESOURCE_TYPE, core.Id)]

    [#local otaBucket = ""]
    [#local otaPrefix = ""]
    [#local otaURL = ""]

    [#local releaseChannel = getOccurrenceSettingValue(occurrence, "RELEASE_CHANNEL", true)?has_content?then(
            getOccurrenceSettingValue(occurrence, "RELEASE_CHANNEL", true),
            environmentName
    )]

    [#local codeSrcBucket = getRegistryEndPoint("scripts", occurrence)]
    [#local codeSrcPrefix = formatRelativePath(
                                getRegistryPrefix("scripts", occurrence),
                                    productName,
                                    getOccurrenceBuildUnit(occurrence),
                                    getOccurrenceBuildReference(occurrence))]

    [#local configFilePath = formatRelativePath(
                                getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                                "config" )]
    [#local configFileName = "config.json" ]

    [#list solution.Links?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link) ]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]
            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]

            [#if !(linkTarget.Configuration.Solution.Enabled!true) ]
                [#continue]
            [/#if]

            [#switch linkTargetCore.Type]
                [#case S3_COMPONENT_TYPE ]
                    [#if link.Id?lower_case?starts_with("ota") ]
                        [#local otaBucket = linkTargetAttributes["NAME"]]
                        [#local otaPrefix = core.RelativePath ]
                        [#local otaURL = formatRelativePath("https://", linkTargetAttributes["INTERNAL_FQDN"], otaPrefix )]
                    [/#if]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "mobileapp" : {
                    "Id" : id,
                    "Type" : COT_MOBILEAPP_RESOURCE_TYPE,
                    "ConfigFilePath" : configFilePath,
                    "ConfigFileName" : configFileName,
                    "Deployed" : true
                }
            },
            "Attributes" : {
                "ENGINE" : solution.Engine,
                "APP_BUILD_FORMATS" : solution.BuildFormats?join(","),
                "RELEASE_CHANNEL" : releaseChannel,
                "CODE_SRC_BUCKET" : codeSrcBucket,
                "CODE_SRC_PREFIX" : codeSrcPrefix,
                "OTA_ARTEFACT_BUCKET" : otaBucket,
                "OTA_ARTEFACT_PREFIX" : otaPrefix,
                "OTA_ARTEFACT_URL" : otaURL,
                "CONFIG_FILE" : formatRelativePath(
                                    configFilePath,
                                    configFileName)
            }
        }
    ]
[/#macro]



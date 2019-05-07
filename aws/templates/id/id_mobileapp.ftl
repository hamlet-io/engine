[#-- MOBILEAPP --]

[#-- Resources --]
[#assign COT_MOBILEAPP_RESOURCE_TYPE = "mobileapp"]

[#-- Components --]
[#assign MOBILEAPP_COMPONENT_TYPE = "mobileapp"]

[#assign componentConfiguration +=
    {
        MOBILEAPP_COMPONENT_TYPE : { 
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "mobile apps with over the air update hosting"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
                    "Default" : "expo",
                    "Values" : ["expo"]
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "BuildFormats",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : [ "ios", "android" ],
                    "Values" : [ "ios", "android" ]
                },
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        }
    }]

[#function getMobileAppState occurrence]
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

    [#assign configFilePath = formatRelativePath(
                                getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                                "config" )]
    [#assign configFileName = "config.json" ]

    [#list solution.Links?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link) ]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]
            [#local linkTargetCore = linkTarget.Core ]
            [#assign linkTargetAttributes = linkTarget.State.Attributes ]

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

    [#return
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
[/#function]



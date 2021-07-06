[#ftl]

[#macro shared_view_default_releaseinfo_generationcontract  ]
    [@addDefaultGenerationContract subsets=[ "config" ] /]
[/#macro]

[#macro shared_view_default_releaseinfo ]

    [#local environemnt_vars = {
        ("${accountId}_ACCOUNT_PROVIDER")?upper_case : accountObject.Provider,
        ("${accountId}_${accountObject.Provider}_ACCOUNT_ID")?upper_case : accountObject.ProviderId
    }]

    [#-- Determine the available registries --]
    [#list accountObject["Registry"]["Registries"] as id, details ]
        [#if details?is_hash && details.Enabled ]
            [#switch ((details.Storage)!"")?lower_case ]
                [#case "objectstore"]
                    [#if accountObject.Provider == "aws" ]
                        [#local environemnt_vars += {
                            ("${accountId}_${id}_DNS")?upper_case : getExistingReference(formatAccountS3Id("registry")),
                            ("${accountId}_${id}_REGION")?upper_case : regionId
                        }]
                    [/#if]
                    [#break]

                [#case "snapshotstore"]
                    [#if accountObject.Provider == "aws" ]
                        [#local environemnt_vars += {
                            ("${accountId}_${id}_PREFIX")?upper_case : "registry",
                            ("${accountId}_${id}_REGION")?upper_case : regionId
                        }]
                    [/#if]
                    [#break]

                [#case "providerregistry"]
                    [#if accountObject.Provider == "aws" ]
                        [#local environemnt_vars += {
                            ("${accountId}_${id}_DNS")?upper_case : "${accountObject.ProviderId}.dkr.ecr.${regionId}.amazonaws.com"
                        }]
                    [/#if]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [@addToDefaultJsonOutput
        content={
            "Environment" : environemnt_vars
        }
    /]

[/#macro]

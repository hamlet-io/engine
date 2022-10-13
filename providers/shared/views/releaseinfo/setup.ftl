[#ftl]

[#macro shared_view_default_releaseinfo_generationcontract  ]
    [@addDefaultGenerationContract subsets=[ "config" ] /]
[/#macro]

[#macro shared_view_default_releaseinfo ]

    [#local environemnt_vars = {
        ("${accountId}_ACCOUNT_PROVIDER")?upper_case : accountObject.Provider,
        ("${accountId}_${accountObject.Provider}_ACCOUNT_ID")?upper_case : accountObject.ProviderId
    }]

    [#-- Configured as a fixed set as registries can now be defined and managed within the image object --]
    [#-- This ensures that the existing image registry setup still works --]
    [#local registries =  {
        "contentnode": {
          "Storage": "objectstore"
        },
        "dataset": {
          "Storage": "objectstore"
        },
        "docker": {
          "Storage": "providerregistry"
        },
        "lambda": {
          "Storage": "objectstore"
        },
        "lambda_jar": {
          "Storage": "objectstore"
        },
        "openapi": {
          "Storage": "objectstore"
        },
        "pipeline": {
          "Storage": "objectstore"
        },
        "rdssnapshot": {
          "Storage": "snapshotstore"
        },
        "scripts": {
          "Storage": "objectstore"
        },
        "spa": {
          "Storage": "objectstore"
        },
        "swagger": {
          "Storage": "objectstore"
        }
      }]

    [#-- Determine the available registries --]
    [#list registries as id, details ]
        [#switch ((details.Storage)!"")?lower_case ]
            [#case "objectstore"]
                [#if accountObject.Provider == "aws" ]
                    [#local environemnt_vars += {
                        ("${accountId}_${id}_DNS")?upper_case : getExistingReference(formatAccountS3Id("registry")),
                        ("${accountId}_${id}_REGION")?upper_case : getRegion()
                    }]
                [/#if]
                [#break]

            [#case "snapshotstore"]
                [#if accountObject.Provider == "aws" ]
                    [#local environemnt_vars += {
                        ("${accountId}_${id}_PREFIX")?upper_case : "registry",
                        ("${accountId}_${id}_REGION")?upper_case : getRegion()
                    }]
                [/#if]
                [#break]

            [#case "providerregistry"]
                [#if accountObject.Provider == "aws" ]
                    [#local environemnt_vars += {
                        ("${accountId}_${id}_DNS")?upper_case : "${accountObject.ProviderId}.dkr.ecr.${getRegion()}.amazonaws.com"
                    }]
                [/#if]
                [#break]
        [/#switch]
    [/#list]

    [@addToDefaultJsonOutput
        content={
            "Environment" : environemnt_vars
        }
    /]

[/#macro]

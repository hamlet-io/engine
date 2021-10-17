[#ftl]

[@addLayer
    type=ACCOUNT_LAYER_TYPE
    referenceLookupType=ACCOUNT_LAYER_REFERENCE_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "The deployment provider account layer"
            }
        ]
    inputFilterAttributes=[
            {
                "Id" : ACCOUNT_LAYER_TYPE,
                "Description" : "The deployment provider account"
            }
        ]
    attributes=[
        {
            "Names" : "Id",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Provider",
            "Types" : STRING_TYPE,
            "Default" : "aws",
            "Description" : "Define which provider this account applies to"
        },
        {
            "Names" : "Name",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Region",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Domain",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Deployment",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Policy",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
        {
            "Names" : "DeploymentProfiles",
            "SubObjects" : true,
            "Children" : []
        },
        {
            "Names" : "PolicyProfiles",
            "SubObjects" : true,
            "Children" : []
        }
        {
            "Names" : "Modules",
            "SubObjects" : true,
            "AttributeSet" : MODULE_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Plugins",
            "SubObjects" : true,
            "AttributeSet" : PLUGIN_ATTRIBUTESET_TYPE
        },
        {
            "Names" :[
                "ProviderId",
                "AWSId",
                "AzureId"
            ],
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Seed",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "CostCentre",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Console",
            "Children" : [
                {
                    "Names" : "Encryption",
                    "Children" : [
                        {
                            "Names" : "DedicatedKey",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : "LoggingDestinations",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Values" : [ "cloudwatch", "s3" ],
                    "Default" : [ "s3" ]
                }
            ]
        },
        {
            "Names" : "S3",
            "Children" : [
                {
                    "Names" : "Encryption",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "EncryptionSource",
                            "Types" : STRING_TYPE,
                            "Values" : [ "EncryptionService", "aws:kms", "localservice", "aes256" ],
                            "Default" : "EncryptionService"
                        }
                        {
                            "Names" : "Encryption",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : "Versioning",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Volume",
            "Children" : [
                {
                    "Names" : "Encryption",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "aws:ecsAccountSettings",
            "Types" : OBJECT_TYPE,
            "Default" : {
                "serviceLongArnFormat" : true,
                "taskLongArnFormat" : true,
                "containerInstanceLongArnFormat" : true,
                "awsvpcTrunking" : true
            }
        },
        {
            "Names" : "Audit",
            "Children" : [
                {
                    "Names" : "Expiration",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "Offline",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                }
            ]
        },
        {
            "Names" : "Encryption",
            "Children" : [
                {
                    "Names" : "Alias",
                    "Children" : [
                        {
                            "Names" : "IncludeSeed",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Access",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "AWSId",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                }
            ]
        },
        {
            "Names" : "Registry",
            "Children" : [
                {
                    "Names" : "ShareAccess",
                    "Children" : [
                        {
                            "Names" : "AWSAccounts",
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
                        }
                    ],
                    "Names" : "ReplicaRegions",
                    "Description" : "A list of regions to replicate registries to",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Registries",
                    "Description" : "Defines the registries available for image hosting",
                    "Children" : [
                        {
                            "Names" : "dataset",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "objectstore" ],
                                    "Default" : "objectstore"
                                }
                            ]
                        },
                        {
                            "Names" : "contentnode",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "objectstore" ],
                                    "Default" : "objectstore"
                                }
                            ]
                        },
                        {
                            "Names" : "lambda",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "objectstore" ],
                                    "Default" : "objectstore"
                                }
                            ]
                        },
                        {
                            "Names" : "pipeline",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "objectstore" ],
                                    "Default" : "objectstore"
                                }
                            ]
                        },
                        {
                            "Names" : "scripts",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "objectstore" ],
                                    "Default" : "objectstore"
                                }
                            ]
                        },
                        {
                            "Names" : "spa",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "objectstore" ],
                                    "Default" : "objectstore"
                                }
                            ]
                        },
                        {
                            "Names" : "swagger",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "objectstore" ],
                                    "Default" : "objectstore"
                                }
                            ]
                        },
                        {
                            "Names" : "openapi",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "objectstore" ],
                                    "Default" : "objectstore"
                                }
                            ]
                        },
                        {
                            "Names" : [ "rdssnapshot", "dbsnapshot" ],
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Type" : STRING_TYPE,
                                    "Values" : [ "snapshotstore" ],
                                    "Default" : "snapshotstore"
                                }
                            ]
                        },
                        {
                            "Names" : "docker",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Storage",
                                    "Description" : "How the images are stored",
                                    "Values" : [ "providerregistry" ],
                                    "Default" : "providerregistry"
                                }
                            ]
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Operations",
            "Children" : [
                {
                    "Names" : "Expiration",
                    "Types" : NUMBER_TYPE
                }
            ]
        },
        {
            "Names" : "aws:SES",
            "Description" : "AWS SES Account configuration",
            "Children" : [
                {
                    "Names" : "RuleSet",
                    "Description" : "Ruleset details. Only one active per account",
                    "Children" : [
                        {
                            "Names" : "Name",
                            "Description" : "Name of the ruleset",
                            "Types" : STRING_TYPE,
                            "Default" : "account-default"
                        }
                    ]
                },
                {
                    "Names" : "IPAddressGroups",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : "TagSet",
            "Description" : "The TagSet to apply",
            "Type" : STRING_TYPE,
            "Default" : "default"
        }
    ]
/]

[#-- Temporary function --]
[#-- TODO(mfl) remove once integrated into the input pipeline --]
[#function getAccountLayerRegion ]
    [#local account = getActiveLayer(ACCOUNT_LAYER_TYPE) ]
    [#return (account[getCLODeploymentUnit()].Region)!account.Region!""]
[/#function]

[#function getAccountLayerFilters filter]
    [#local result = filter ]

    [#local account = getActiveLayer(ACCOUNT_LAYER_TYPE) ]

    [#-- Special defaulting for region --]
    [#if ! isFilterAttribute(filter, "Region") ]
        [#local result += attributeIfContent("Region", getAccountLayerRegion()) ]
    [/#if]

    [#-- Special defaulting for provider --]
    [#if ! isFilterAttribute(filter, "Provider") ]
        [#local result += attributeIfContent("Provider", account.Provider!"") ]
    [/#if]

    [#return result]
[/#function]

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
            "Subobjects" : true,
            "Children" : []
        },
        {
            "Names" : "PolicyProfiles",
            "Subobjects" : true,
            "Children" : []
        }
        {
            "Names" : "Modules",
            "Subobjects" : true,
            "Children"  : moduleReferenceConfiguration
        },
        {
            "Names" : "Plugins",
            "Subobjects" : true,
            "Children" : pluginReferenceConfiguration
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
            "Subobjects" : true,
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
        }
    ]
/]

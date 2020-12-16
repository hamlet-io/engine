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
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Provider",
            "Type" : STRING_TYPE,
            "Default" : "aws",
            "Description" : "Define which provider this account applies to"
        },
        {
            "Names" : "Name",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Deployment",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Policy",
                    "Type" : ARRAY_OF_STRING_TYPE,
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
            "Type" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Seed",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "CostCentre",
            "Type" : STRING_TYPE,
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
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : "LoggingDestinations",
                    "Type" : ARRAY_OF_STRING_TYPE,
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
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "EncryptionSource",
                            "Type" : STRING_TYPE,
                            "Values" : [ "EncryptionService", "aws:kms", "localservice", "aes256" ],
                            "Default" : "EncryptionService"
                        }
                        {
                            "Names" : "Encryption",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : "Versioning",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
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
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "aws:ecsAccountSettings",
            "Type" : OBJECT_TYPE,
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
                    "Type" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "Offline",
                    "Type" : [ NUMBER_TYPE, STRING_TYPE ]
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
                            "Type" : BOOLEAN_TYPE,
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
                    "Type" : STRING_TYPE,
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
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
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
                    "Type" : NUMBER_TYPE
                }
            ]
        }
    ]
/]

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
            "Description" : "A hamlet specific unique Id for the Account",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Description" : "A hamlet specific unique name for the Account - Uses Id if not defined",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Description" : "A long form title of the account for documentation",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Description" : "A description of the account",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Provider",
            "Description" : "The name of the provider that the account belongs to",
            "Types" : STRING_TYPE,
            "Default" : "aws"
        },
        {
            "Names" :[
                "ProviderId",
                "AWSId",
                "AzureId"
            ],
            "Description" : "The unique Id of the account from the provider",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Region",
            "Description" : "The id of a Region Reference to use as the default",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Domain",
            "Description" : "The id of a Domain Reference to use as the default",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Profiles",
            "Description" : "Account wide profiles to apply to account and child resources",
            "Children" : [
                {
                    "Names" : "Deployment",
                    "Description" : "The id of a DeploymentProfile Reference or Account attribute to apply to all components",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Policy",
                    "Description" : "The id of a PolicyProfile Reference or Account attribute to apply to all components",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
        {
            "Names" : "DeploymentProfiles",
            "Description" : "Account specific DeploymentProfiles to apply across all account components",
            "SubObjects" : true,
            "Children" : []
        },
        {
            "Names" : "PolicyProfiles",
            "Description" : "Account specific PolicyProfiles to apply across all account components",
            "SubObjects" : true,
            "Children" : []
        }
        {
            "Names" : "Modules",
            "Description" : "Modules to import and apply for any component that belongs to the account",
            "SubObjects" : true,
            "AttributeSet" : MODULE_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Plugins",
            "Description" : "Pluings to import and apply for any component that belongs to the account",
            "SubObjects" : true,
            "AttributeSet" : PLUGIN_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Seed",
            "Description" : "A random seed to ensure global resource names are unique",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "CostCentre",
            "Description" : "A cost centre tag to apply to all components the account belongs to",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Console",
            "Description" : "Configuration control for virtual machine consoles",
            "Children" : [
                {
                    "Names" : "Encryption",
                    "Description" : "Enable encryption of all content between the virtual machine and the console service",
                    "Children" : [
                        {
                            "Names" : "DedicatedKey",
                            "Description" : "Use a dedicated KMS key instead of the default account kms key",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : [ "LoggingDestinations", "aws:LoggingDestinations" ],
                    "Description" : "AWS: where logs from the console session will be sent",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Values" : [ "cloudwatch", "s3" ],
                    "Default" : [ "s3" ]
                }
            ]
        },
        {
            "Names" : "S3",
            "Description" : "Account level S3/Object store configuration",
            "Children" : [
                {
                    "Names" : "Encryption",
                    "Description" : "At-rest encryption management",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "EncryptionSource",
                            "Description" : "The encryption service to use to encrypt data",
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
                    "Description" : "Enable versioning on all account level object stores",
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
            "Description" : "Account wide controls over block storage volumes",
            "Children" : [
                {
                    "Names" : "Encryption",
                    "Description" : "Manage at-rest encryption of volumes",
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
            "Description" : "AWS manage account level configuration of the Elastic Container Service",
            "Types" : OBJECT_TYPE,
            "Default" : {
                "awsvpcTrunking": true,
                "containerInsights": true
            }
        },
        {
            "Names" : "Audit",
            "Description": "Manage the object store audit logging",
            "Children" : [
                {
                    "Names" : "Expiration",
                    "Description" : "The duration to keep logs for",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "Offline",
                    "Description" : "The duration to keep logs before sending to offline storage",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names": "ReplicationRules",
                    "Description" : "Manage replication of the audit bucket to another location",
                    "SubObjects": true,
                    "Children": [
                        {
                            "Names" : "Enabled",
                            "Description" : "Is the rule enabled",
                            "Types": BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names": "Priority",
                            "Description" : "The priority of the rule when handling conflicts",
                            "Types" : NUMBER_TYPE,
                            "Default" : 100
                        },
                        {
                            "Names" : "Destination",
                            "Children" : [
                                {
                                    "Names" : "Id",
                                    "Description" : "The unique Id of the destination that will receive the data",
                                    "Types" : STRING_TYPE,
                                    "Mandatory" : true
                                },
                                {
                                    "Names": "ProviderId",
                                    "Description" : "The Cloud Provider Id of where the destination is hosted - set to __local__ for own account",
                                    "Types" : STRING_TYPE,
                                    "Default" : "__local__"
                                }
                            ]
                        },
                        {
                            "Names": "Filters",
                            "Description" : "The filters to apply on objects that should be replicated",
                            "SubObjects" : true,
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Description" : "Is the filter enabled",
                                    "Types": BOOLEAN_TYPE,
                                    "Default" : true
                                }
                                {
                                    "Names" : "Type",
                                    "Types" : STRING_TYPE,
                                    "Description" : "The type of prefix to use",
                                    "Values" : [ "Prefix", "Tag" ],
                                    "Mandatory" : true
                                },
                                {
                                    "Names": "Type:Prefix",
                                    "Description" : "Prefix specific controls applied on the filter",
                                    "Children" : [
                                        {
                                            "Names" : "Prefix",
                                            "Description" : "The prefix to filter objects based on",
                                            "Types" : STRING_TYPE
                                        }
                                    ]
                                },
                                {
                                    "Names" : "Type:Tag",
                                    "Children" : [
                                        {
                                            "Names" : "Key",
                                            "Description" : "The key of the Tag",
                                            "Types" : STRING_TYPE
                                        },
                                        {
                                            "Names" : "Value",
                                            "Description" : "The vlaue of the Tag",
                                            "Types" : STRING_TYPE
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Encryption",
            "Description" : "Manage Account level encryption keys",
            "Children" : [
                {
                    "Names" : "Alias",
                    "Description" : "Control the alias of the KMS Key",
                    "Children" : [
                        {
                            "Names" : "IncludeSeed",
                            "Description" : "Include a unique seed in the alias to ensure it is unique in the account",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Registry",
            "Description" : "Manage the registries used to host account based copies for images",
            "Children" : [
                {
                    "Names" : "ShareAccess",
                    "Description"  : "Control access to the registries from external sources",
                    "Children" : [
                        {
                            "Names" : ["ProviderIds", "AWSAccounts" ],
                            "Description" : "The provider Ids of provider accounts to share with",
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
            "Description" : "Account wide control over the operations object store created within segments",
            "Children" : [
                {
                    "Names" : "Expiration",
                    "Description" : "The maximum time to keep opbjects in operations stores",
                    "Types" : NUMBER_TYPE
                }
            ]
        },
        {
            "Names" : "aws:SES",
            "Description" : "AWS: Simple Email Service Account wide configuration",
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
                    "Names" : "IPAccessPolicy",
                    "Description" : "Controls how IPAddressGroups are handled - deny: deny these groups - allow: only allow these groups",
                    "Types" : STRING_TYPE,
                    "Values" : [ "allow", "deny"],
                    "Default" : "allow"
                },
                {
                    "Names" : "IPAddressGroups",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : "Logging",
            "Description" : "Account level resource logging configuration",
            "Children" : [
                {
                    "Names" : "Encryption",
                    "Description" : "Manage at-rest encryption of log storage",
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
            "Names": "ProviderAuditing",
            "Description": "Logging of cloud service provider actions",
            "Children" : [
                {
                    "Names": "Enabled",
                    "Description" : "Is the logging service enabled",
                    "Types": BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Scope",
                    "Description" : "The Scope of the logging sent to this account - Account = this account, Tenancy = all accounts in tenancy",
                    "Types" : STRING_TYPE,
                    "Values" : [ "Account", "Tenancy"],
                    "Default" : "Account"
                },
                {
                    "Names": "Encryption",
                    "Description" : "Manage at-rest encryption of data storage",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "StorageLocations",
                    "Description": "Where to store the audit logs",
                    "SubObjects": true,
                    "Children" : [
                        {
                            "Names" : "Type",
                            "Description" : "The type of storage to use",
                            "Values" : [ "Object", "Logs" ],
                            "Default" : "Object"
                        },
                        {
                            "Names": "Type:Object",
                            "Children" : [
                                {
                                    "Names" : "Prefix",
                                    "Description" : "A prefix to apply to objects store in logs - _provider = use the providers service name",
                                    "Default" : "_provider"
                                }
                            ]
                        }
                    ]
                },
                {
                    "Names": "aws:InsightReporting",
                    "Description" : "Enable proactive insight monitor logging",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
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

[#-- Provider Account Query --]
[#function getProviderAccountIds accountIds ]
    [#local ProviderAccountIds = [] ]

    [#list accountIds as accountId ]
        [#switch accountId]
            [#case "_tenant"]
            [#case "_tenant_"]
            [#case "__tenant__"]
                [#list accounts as id,account ]
                    [#local ProviderAccountIds += [ (account.ProviderId)!""]  ]
                [/#list]
                [#break]

            [#case "_environment"]
            [#case "_environment_"]
            [#case "__environment__"]
                [#local ProviderAccountIds += [ accountObject.ProviderId ] ]
                [#break]

            [#case "_global" ]
            [#case "_global_" ]
            [#case "__global__" ]
                [#local ProviderAccountIds += [ "*" ]]
                [#break]

            [#default]
                [#local ProviderAccountIds += [ (accounts[accountId].ProviderId)!"" ]]
        [/#switch]
    [/#list]
    [#return ProviderAccountIds ]
[/#function]

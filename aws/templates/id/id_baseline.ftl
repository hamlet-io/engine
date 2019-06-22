[#-- Resources --]
[#assign LOCAL_SSH_PRIVATE_KEY_RESOURCE_TYPE = "sshPrivKey" ]
[#assign AWS_SSH_KEY_PAIR_RESOURCE_TYPE = "sshKeyPair" ]

[#assign AWS_CMK_RESOURCE_TYPE = "cmk" ]
[#assign AWS_CMK_ALIAS_RESOURCE_TYPE = "cmkalias" ]

[#-- Components --]
[#assign BASELINE_COMPONENT_TYPE = "baseline" ]
[#assign BASELINE_DATA_COMPONENT_TYPE = "baselinedata" ]
[#assign BASELINE_KEY_COMPONENT_TYPE = "baselinekey" ]

[#assign componentConfiguration +=
    {
        BASELINE_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A set of resources required for every segment deployment"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Seed",
                    "Children" : [
                        {
                            "Names" : "Length",
                            "Type" : NUMBER_TYPE,
                            "Default" : 10
                        }
                    ]
                }
            ],
            "Components" : [
                {
                    "Type" : BASELINE_DATA_COMPONENT_TYPE,
                    "Component" : "DataBuckets",
                    "Link" : ["DataBucket"]
                },
                {
                    "Type" : BASELINE_KEY_COMPONENT_TYPE,
                    "Component" : "Keys",
                    "Link" : ["Key"]
                }
            ]
        },
        BASELINE_DATA_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A segment shared data store"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Role",
                    "Type" : STRING_TYPE,
                    "Values" : [ "appdata", "operations" ],
                    "Mandatory" : true
                },
                {
                    "Names" : "Lifecycles",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Prefix",
                            "Types" : STRING_TYPE,
                            "Description" : "The prefix to apply the lifecycle to"
                        }
                        {
                            "Names" : "Expiration",
                            "Types" : [STRING_TYPE, NUMBER_TYPE],
                            "Description" : "Provide either a date or a number of days",
                            "Default" : "_operations"
                        },
                        {
                            "Names" : "Offline",
                            "Types" : [STRING_TYPE, NUMBER_TYPE],
                            "Description" : "Provide either a date or a number of days",
                            "Default" : "_operations"
                        }
                    ]
                },
                {
                    "Names" : "Versioning",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Notifications",
                    "Subobjects" : true,
                    "Children" : s3NotificationChildConfiguration
                }
            ]
        },
        BASELINE_KEY_COMPONENT_TYPE : {
                "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "Shared security keys for a segment"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
                    "Values" : [ "cmk", "ssh", "oai" ],
                    "Mandatory" : true
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                }
            ]
        }
    }]


[#function getBaselineState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local segmentSeedId = formatSegmentSeedId() ]
    [#if !(getExistingReference(segmentSeedId)?has_content) ]
        [#if legacyVpc ]
            [#assign segmentSeedValue = vpc?remove_beginning("vpc-")]
        [#else]
            [#assign segmentSeedValue = ( runId + accountObject.Seed)[0..(solution.Seed.Length - 1)]  ]
        [/#if]
    [#else]
        [#assign segmentSeedValue = getExistingReference(segmentSeedId) ]
    [/#if]

    [#local result =
        {
            "Resources" : {
                "segmentSeed": {
                    "Id" : segmentSeedId,
                    "Value" : segmentSeedValue,
                    "Type" : SEED_RESOURCE_TYPE
                }
            } +
            (!legacyVpc)?then(
                {
                    "segmentSNSTopic" : {
                        "Id" : formatSegmentSNSTopicId(),
                        "Type" : AWS_SNS_TOPIC_RESOURCE_TYPE
                    }
                },
                {}
            ),
            "Attributes" : {
                "SEED_SEGMENT" : segmentSeedValue
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]

[#function getBaselineStorageState occurrence parent ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentCore = occurrence.Core ]
    [#local parentState = parent.State ]
    [#local segmentSeed = parentState.Attributes["SEED_SEGMENT"] ]

    [#local role = solution.Role]
    [#local legacyS3 = false]

    [#local bucketId = formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, core.SubComponent.Id ) ]
    [#local bucketName = formatSegmentBucketName( segmentSeed, core.SubComponent.Id )]]

    [#switch core.SubComponent.Id ]
        [#case "appdata" ]
            [#local bucketName = formatSegmentBucketName(segmentSeed, "data") ]
            [#if getExistingReference(formatS3DataId())?has_content ]
                [#local bucketId = formatS3DataId() ]
                [#local legacyS3 = true ]
            [/#if]
            [#break]

        [#case "opsdata" ]
            [#local bucketName = formatSegmentBucketName(segmentSeed, "ops") ]
            [#if getExistingReference(formatS3OperationsId())?has_content ]
                [#local bucketId = formatS3OperationsId() ]
                [#local legacyS3 = true]
            [/#if]
            [#break]
    [/#switch]

    [#local bucketPolicyId = formatDependentBucketPolicyId(bucketId)]

    [#local result =
        {
            "Resources" : {
                "bucket" : {
                    "Id" : bucketId,
                    "Name" : bucketName,
                    "Type" : AWS_S3_RESOURCE_TYPE,
                    "LegacyS3" : legacyS3
                },
                "bucketpolicy" : {
                    "Id" : bucketPolicyId,
                    "Type" : AWS_S3_BUCKET_POLICY_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]

[#function getBaselineKeyState occurrence parent ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentCore = occurrence.Core ]
    [#local parentState = parent.State ]

    [#local resources = {}]
    [#local attributes = {}]

    [#switch solution.Engine ]
        [#case "cmk"]
            [#local legacyKey = false]

            [#if core.SubComponent.Id == "cmk" &&
                    getExistingReference(formatSegmentCMKId(), "","", "cmk" )?has_content ]
                [#local cmkId = formatSegmentCMKTemplateId()]
                [#local cmkName = formatSegmentFullName()]
                [#local cmkAliasId = formatSegmentCMKAliasId(cmkId)]
                [#local cmkAliasName = formatSegmentFullName() ]
                [#local legacyKey = true ]
            [#else]
                [#local cmkId = formatResourceId(AWS_CMK_RESOURCE_TYPE, core.Id )]
                [#local cmkName = core.FullName]
                [#local cmkAliasId = formatResourceId(AWS_CMK_ALIAS_RESOURCE_TYPE, core.Id )]
                [#local cmkAliasName = core.FullName ]
            [/#if]

            [#local cmkOutputId = legacyKey?then(formatSegmentCMKId(), cmkId)]

            [#local resources += 
                {
                    "cmk" : {
                        "Id" : cmkOutputId,
                        "ResourceId" : cmkId,
                        "Name" : cmkName,
                        "Type" : AWS_CMK_RESOURCE_TYPE,
                        "LegacyKey": legacyKey
                    },
                    "cmkAlias" : {
                        "Id" : cmkAliasId,
                        "Name" : formatRelativePath( "alias", cmkName),
                        "Type" : AWS_CMK_ALIAS_RESOURCE_TYPE
                    }
                }
            ]
            [#local attributes += { "KEY_ID" : cmkOutputId }]

            [#break]

        [#case "ssh"]
            [#local legacyKey = false]
            [#if core.SubComponent.Id == "ssh" &&
                    getExistingReference(formatEC2KeyPairId(), NAME_ATTRIBUTE_TYPE)?has_content ]
                [#local keyPairId = formatEC2KeyPairId()]
                [#local keyPairName = formatSegmentFullName() ]
                [#local legacyKey = true ]
            [#else]
                [#local keyPairId = formatResourceId(AWS_SSH_KEY_PAIR_RESOURCE_TYPE, core.Id)]
                [#local keyPairName = core.FullName ]
            [/#if]

            [#local resources += 
                {
                    "localKeyPair" : {
                        "Id" : formatResourceId(LOCAL_SSH_PRIVATE_KEY_RESOURCE_TYPE, core.Id),
                        "PrivateKey" : formatName(".aws", accountObject.Id, regionId, core.SubComponent.Name, "prv") + ".pem",
                        "PublicKey" : formatName(".aws", accountObject.Id, regionId, core.SubComponent.Name, "crt") + ".pem",
                        "Type" : LOCAL_SSH_PRIVATE_KEY_RESOURCE_TYPE
                    },
                    "ec2KeyPair" : {
                        "Id" : keyPairId,
                        "Name" : keyPairName,
                        "Type" : AWS_SSH_KEY_PAIR_RESOURCE_TYPE,
                        "LegacyKey": legacyKey
                    }
                }
            ]

            [#local attributes += { "KEY_ID" : keyPairId }]
            [#break]
        [#case "oai"]

            [#local OAIId = formatResourceId( AWS_CLOUDFRONT_ACCESS_ID_RESOURCE_TYPE, core.Id) ]
            [#local OAIName = core.FullName ]

            [#local resources += 
                {
                    "originAccessId" : {
                        "Id" : OAIId,
                        "Name" : OAIName,
                        "Type" : AWS_CLOUDFRONT_ACCESS_ID_RESOURCE_TYPE
                    }
                }
            ]
            [#local attributes += { "KEY_ID" : OAIId }]

            [#break]
        [#default]
            [@cfException
                mode=listMode
                description="Unsupported Key Type"
                detail=solution.Engine
                context=occurrence
            /]
    [/#switch]

    [#local result =
        {
            "Resources" : resources,
            "Attributes" : attributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]

[#-- Resources --]
[#assign SEED_RESOURCE_TYPE = "seed" ]

[#function formatSegmentSeedId ]
    [#return formatSegmentResourceId(SEED_RESOURCE_TYPE)]
[/#function]


[#-- Baseline Databucket legacy Id formatting --]
[#function formatS3BaselineId role ]
    [#return formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, role)]
[/#function]

[#function formatS3OperationsId]
    [#return
        migrateToResourceId(
            formatSegmentS3Id("ops"),
            formatSegmentS3Id("operations"),
            formatSegmentS3Id("logs")
        )]
[/#function]

[#function formatS3DataId]
    [#return
        migrateToResourceId(
            formatSegmentS3Id("data"),
            formatSegmentS3Id("application"),
            formatSegmentS3Id("backups")
        )]
[/#function]    

[#--- Baseline Key Legacy Id formatting --]
[#function formatEC2KeyPairId extensions...]
    [#return formatSegmentResourceId(
                AWS_EC2_KEYPAIR_RESOURCE_TYPE,
                extensions)]
[/#function]

[#function formatSegmentCMKId ]
    [#return
        migrateToResourceId(
            formatSegmentResourceId(AWS_CMK_RESOURCE_TYPE),
            formatSegmentResourceId(AWS_CMK_RESOURCE_TYPE, AWS_CMK_RESOURCE_TYPE)
        )]
[/#function]

[#function formatSegmentCMKTemplateId ]
    [#return 
        getExistingReference(
            formatSegmentResourceId(AWS_CMK_RESOURCE_TYPE,"cmk"))?has_content?then(
                AWS_CMK_RESOURCE_TYPE,
                formatSegmentResourceId(AWS_CMK_RESOURCE_TYPE)
            )]
[/#function]

[#function formatSegmentCMKAliasId cmkId]
    [#return
      (cmkId == AWS_CMK_RESOURCE_TYPE)?then(
        formatDependentResourceId("alias", cmkId),
        formatDependentResourceId(AWS_CMK_ALIAS_RESOURCE_TYPE, cmkId))]
[/#function]

[#-- Link based lookups for Baseline SubComponents --]
[#function getBaselineKeyId id ]
    [#assign cmkKeyLink = getLinkTarget( 
        {}, 
        {
            "Tier" : "mgmt",
            "Component" : "baseline",
            "Key" : id,
            "Instance" : "",
            "Version" : ""
        },
        false
    )]
    [#return cmkKeyLink.State.Attributes["KEY_ID"] ]
[/#function]

[#function getBaselineDataBucketId id ]
    [#assign dataBucketLink = getLinkTarget(
            {},
            {
                "Tier" : "mgmt",
                "Component" : "baseline",
                "DataBucket" : id,
                "Instance" : "",
                "Version" : ""
            },
            false
    )]
    [#return dataBucketLink.State.Resources["bucket"].Id ]
[/#function]
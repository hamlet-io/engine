[#-- Components --]
[#assign BASELINE_COMPONENT_TYPE = "baseline" ]
[#assign BASELINE_DATA_COMPONENT_TYPE = "baselinedata" ]
[#assign BASELINE_KEYS_COMPONENT_TYPE = "baselinekeys" ]

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
                    "Type" : BASELINE_KEYS_COMPONENT_TYPE,
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
        BASELINE_KEYS_COMPONENT_TYPE : {
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

    [#local bucketId = formatSegmentS3Id(core.SubComponent.Id ) ]
    [#local bucketName = formatSegmentBucketName( segmentSeed, core.SubComponent.Id )]]

    [#switch core.SubComponent.Id ]
        [#case "appdata" ]
            [#local bucketName = formatSegmentBucketName(segmentSeed, "data") ]
            [#local bucketId = formatS3DataId() ]
            [#if getExistingReference(formatS3DataId())?has_content ]
                [#local legacyS3 = true ]
            [/#if]
            [#break]

        [#case "opsdata" ]
            [#local bucketName = formatSegmentBucketName(segmentSeed, "ops") ]
            [#local bucketId = formatS3OperationsId()]
            [#if getExistingReference(formatS3OperationsId())?has_content ]
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

    [#local legacyKey = false]

    [#local resources = {}]

    [#switch solution.Engine ]
        [#case "cmk"]
            
            [#if core.SubComponent.Id == "cmk" &&
                    getExistingReference(formatSegmentCMKTemplateId())?has_content ]
                [#local cmkId = formatSegmentCMKTemplateId()]
                [#local cmkAliasId = formatSegmentCMKAliasId(cmkId)]
                [#local legacyKey = true ]
            [#else]
                [#local cmkId = formatResourceId(AWS_CMK_RESOURCE_TYPE, core.Id )]
                [#local cmkAliasId = formatResourceId(AWS_CMK_ALIAS_RESOURCE_TYPE, core.Id )]
            [/#if]

            [#local resources += 
                {
                    "cmk" : {
                        "Id" : cmkId,
                        "Name" : core.FullName,
                        "Type" : AWS_CMK_RESOURCE_TYPE
                    },
                    "cmkAlias" : {
                        "Id" : cmkAliasId,
                        "Name" : "alias/" + core.FullName,
                        "Type" : AWS_CMK_ALIAS_RESOURCE_TYPE
                    }
                }
            ]

            [#break]
        [#case "ssh"]
            [#break]
        [#case "oai"]

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

[#-- Resources --]
[#assign SEED_RESOURCE_TYPE = "seed" ]

[#function formatSegmentSeedId ]
    [#return formatSegmentResourceId(SEED_RESOURCE_TYPE)]
[/#function]

[#function formatS3BaselineId role ]
    [#return formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, role)]
[/#function]

[#function formatS3OperationsId]
    [#return
        migrateToResourceId(
            formatSegmentS3Id("opsdata"),
            [
                formatSegmentS3Id("ops"),
                formatSegmentS3Id("operations"),
                formatSegmentS3Id("logs")
            ]
        )]
[/#function]

[#function formatS3DataId]
    [#return
        migrateToResourceId(
            formatSegmentS3Id("appdata"),
            [
            formatSegmentS3Id("data"),
            formatSegmentS3Id("application"),
            formatSegmentS3Id("backups")
            ]
        )]
[/#function]
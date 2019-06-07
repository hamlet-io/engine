[#-- Resources --]
[#assign LOCAL_SSH_PRIVATE_KEY_RESOURCE_TYPE = "sshPrivKey" ]
[#assign AWS_SSH_KEY_PAIR_RESOURCE_TYPE = "sshKeyPair" ]
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

[#macro aws_baseline_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local segmentSeedId = formatSegmentSeedId() ]
    [#if !(getExistingReference(segmentSeedId)?has_content) ]
        [#if legacyVpc ]
            [#local segmentSeedValue = vpc?remove_beginning("vpc-")]
        [#else]
            [#local segmentSeedValue = ( runId + accountObject.Seed)[0..(solution.Seed.Length - 1)]  ]
        [/#if]
    [#else]
        [#local segmentSeedValue = getExistingReference(segmentSeedId) ]
    [/#if]

    [#assign componentState =
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
[/#macro]

[#macro aws_baselinedata_cf_state occurrence parent={} baseState={}  ]
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

    [#assign componentState =
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
[/#macro]

[#macro aws_baselinekey_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentCore = occurrence.Core ]
    [#local parentState = parent.State ]

    [#local resources = {}]

    [#switch solution.Engine ]
        [#case "cmk"]
            [#local legacyKey = false]
            [#if core.SubComponent.Id == "cmk" &&
                    getExistingReference(formatSegmentCMKTemplateId())?has_content ]
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

            [#local resources +=
                {
                    "cmk" : {
                        "Id" : legacyVpc?then(formatSegmentCMKId(), cmkId),
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

            [#break]
        [#default]
            [@cfException
                mode=listMode
                description="Unsupported Key Type"
                detail=solution.Engine
                context=occurrence
            /]
    [/#switch]

    [#assign componentState =
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
[/#macro]

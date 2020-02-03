[#ftl]
[#assign LOCAL_SSH_PRIVATE_KEY_RESOURCE_TYPE = "sshPrivKey" ]

[#macro aws_baseline_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local segmentSeedId = formatSegmentSeedId() ]
    [#if !(getExistingReference(segmentSeedId)?has_content) ]
        [#if legacyVpc ]
            [#local segmentSeedValue = vpc?remove_beginning("vpc-")]
        [#else]
            [#local segmentSeedValue = ( commandLineOptions.Run.Id + accountObject.Seed)[0..(solution.Seed.Length - 1)]  ]
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
            },
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

[#macro aws_baselinedata_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentCore = occurrence.Core ]
    [#local parentState = parent.State ]
    [#local segmentSeed = parentState.Attributes["SEED_SEGMENT"] ]

    [#local role = solution.Role]
    [#local legacyS3 = false]

    [#local bucketId = formatOccurrenceS3Id( occurrence) ]
    [#local bucketName = formatOccurrenceBucketName( occurrence )]]

    [#switch core.SubComponent.Id ]
        [#case "appdata" ]
            [#local bucketId = formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, core.SubComponent.Id ) ]
            [#local bucketName = formatSegmentBucketName(segmentSeed, "data") ]

            [#if getExistingReference(formatS3DataId())?has_content ]
                [#local bucketId = formatS3DataId() ]
                [#local legacyS3 = true ]
            [/#if]
            [#break]

        [#case "opsdata" ]
            [#local bucketId = formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, core.SubComponent.Id ) ]
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
                "BUCKET" : getExistingReference(bucketId)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

[#macro aws_baselinekey_cf_state occurrence parent={} ]
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

            [#local attributes +=
                {
                    "ID" : getExistingReference(cmkOutputId),
                    "ARN" : getExistingReference(cmkOutputId, ARN_ATTRIBUTE_TYPE)
                }
            ]

            [#break]

        [#case "cmk-account" ]
            [#local cmkId = formatAccountCMKTemplateId()]
            [#local resources +=
                {
                    "cmk" : {
                        "Id" : cmkId,
                        "Type" : AWS_CMK_RESOURCE_TYPE
                    }
                }
            ]
            [#local attributes +=
                {
                    "ID" : getExistingReference(cmkId),
                    "ARN" : getExistingReference(cmkId, ARN_ATTRIBUTE_TYPE)
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
            [@fatal
                message="Unsupported Key Type"
                detail=solution.Engine
                context=occurrence
            /]
    [/#switch]

    [#assign componentState =
        {
            "Resources" : resources,
            "Attributes" : attributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

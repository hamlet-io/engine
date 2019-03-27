[#-- Components --]
[#assign BASELINE_COMPONENT_TYPE = "baseline" ]
[#assign BASELINE_DATA_COMPONENT_TYPE = "baselinedata" ]

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
                    "Values" : [ "application", "operations" ],
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
        }
    }]


[#function getBaselineState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local segmentSeedId = formatSegmentSeedId() ]
    [#local result =
        {
            "Resources" : {
                "segmentSeed": {
                    "Id" : segmentSeedId,
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
                "SEED_SEGMENT" : getExistingReference(segmentSeedId)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]


[#function getBaselineStorageState occurrence ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local role = solution.Role]
    [#local baselineDeployment = true]
    [#switch role ]
        [#case "application" ]
            [#local bucketName = dataBucket ]
            [#if getExistingReference(formatS3DataId())?has_content ]
                [#local bucketId = formatS3DataId() ]
                [#local baselineDeployment = false ]
            [#else]
                [#local bucketId = formatS3BaselineId( role ) ]
            [/#if]
            [#break]

        [#case "operations"]
            [#local bucketName = operationsBucket ]
            [#if getExistingReference(formatS3OperationsId())?has_content ]
                [#local bucketId = formatS3OperationsId() ]
                [#local baselineDeployment = false ]
            [#else]
                [#local bucketId = formatS3BaselineId( role ) ]
            [/#if]
            [#break]

        [#default]
            [#local bucketId = formatS3BaselineId( role )]
            [#local bucketName = formatS3BaselineName( role )]
    [/#switch]
    
    [#local bucketPolicyId = formatDependentBucketPolicyId(bucketId)]

    [#local result =
        {
            "Resources" : {
                "bucket" : {
                    "Id" : bucketId,
                    "Name" : bucketName,
                    "Type" : AWS_S3_RESOURCE_TYPE,
                    "BaselineDeployment" : baselineDeployment
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

[#-- Resources --]
[#assign SEED_RESOURCE_TYPE = "seed" ]

[#function formatSegmentSeedId ]
    [#return formatSegmentResourceId(SEED_RESOURCE_TYPE)]
[/#function]

[#function formatS3BaselineId role ]
    [#return formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, role)]
[/#function]

[#function formatS3BaselineName role ]
    [#return formatSegmentBucketName(role)]
[/#function]
[#-- Components --]
[#assign BASELINE_COMPONENT_TYPE = "baseline" ]

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

[#-- Resources --]
[#assign SEED_RESOURCE_TYPE = "seed" ]

[#function formatSegmentSeedId ]
    [#return formatSegmentResourceId(SEED_RESOURCE_TYPE)]
[/#function]

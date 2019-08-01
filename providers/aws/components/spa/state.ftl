[#ftl]

[#macro aws_spa_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local cfId  = formatComponentCFDistributionId(core.Tier, core.Component, occurrence)]

    [#assign componentState =
        {
            "Resources" : {} + 
                getExistingReference(cfId)?has_content?then(
                    {
                        "legacyCF" : {
                            "Id" : cfId,
                            "Type" : AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE
                        }
                    },
                    {}
            ),
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]
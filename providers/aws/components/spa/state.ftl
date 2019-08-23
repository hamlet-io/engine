[#ftl]

[#macro aws_spa_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local cfId  = formatComponentCFDistributionId(core.Tier, core.Component, occurrence)]

    [#assign componentState =
        {
            "Resources" : {
                "site" :{
                    "Id" : formatResourceId( SPA_COMPONENT_TYPE, core.Id ),
                    "Deployed" : true,
                    "Type" : SPA_COMPONENT_TYPE
                }
            } + 
            getExistingReference(cfId, "", "", deploymentUnit)?has_content?then(
                {
                    "legacyCF" : {
                        "Id" : cfId,
                        "Type" : AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE
                    }
                },
                {}
            ),
            "Attributes" : {
                "CONFIG_PATH_PATTERN" : solution.ConfigPathPattern
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]
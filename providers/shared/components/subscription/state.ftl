[#ftl]

[#macro shared_subscription_default_state occurrence parent={} ]
    [#local core = getOccurrenceCore(occurrence) ]
    [#local solution = getOccurrenceSolution(occurrence) ]
    [#local locations = getOccurrenceLocations(occurrence) ]

    [#-- Combine any placement attributes with explicitly provided values --]
    [#local attributes =
        ((locations[DEFAULT_RESOURCE_GROUP].Attributes)!{}) +
        attributeIfContent(
            "PROVIDER",
            solution["external:Provider"]!""
        ) +
        attributeIfContent(
            "ACCOUNT",
            solution["external:ProviderId"]!""
        ) +
        attributeIfContent(
            "DEPLOYMENT_FRAMEWORK",
            solution["external:DeploymentFramework"]!""
        )
    ]

    [#assign componentState =
        {
            "Resources" : {
                "external" : {
                    "Id" : formatResourceId(SHARED_EXTERNAL_RESOURCE_TYPE, core.Id),
                    "Type" : SHARED_EXTERNAL_RESOURCE_TYPE,
                    "Deployed" : attributes["PROVIDER"]?has_content
                }
            },
            "Attributes" : attributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

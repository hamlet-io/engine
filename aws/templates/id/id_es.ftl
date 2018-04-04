[#-- ElasticSearch --]

[#-- Resources --]
[#assign AWS_ES_RESOURCE_TYPE = "es" ]

[#function formatElasticSearchId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_ES_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]


[#-- Components --]
[#assign ES_COMPONENT_TYPE = "es"]

[#assign componentConfiguration +=
    {
        ES_COMPONENT_TYPE : [
            {
                "Name" : "IPAddressGroups",
                "Default" : []
            },
            {
                "Name" : "AdvancedOptions",
                "Default" : []
            },
            {
                "Name" : "Version",
                "Default" : 2.3
            },
            {
                "Name" : "Snapshot",
                "Children" : [
                    {
                        "Name" : "Hour",
                        "Default" : ""
                    }
                ]
            }
        ]
    }]

[#function getESState occurrence]
    [#local core = occurrence.Core]

    [#local id = formatResourceId(AWS_ES_RESOURCE_TYPE, core.Id)]

    [#return
        {
            "Resources" : {
                "es" : { 
                    "Id" : id,
                    "Type" : AWS_ES_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "FQDN" : getReference(id, DNS_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
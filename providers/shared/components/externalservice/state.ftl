[#ftl]

[#macro shared_externalservice_default_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local attributes = {}]
    [#if solution.Properties?has_content ]
        [#list solution.Properties?values as property ]
            [#local attributes += { property.Key?upper_case, property.Value }]
        [/#list]
    [/#if]

    [#local environment =
        occurrence.Configuration.Environment.General +
        occurrence.Configuration.Environment.Sensitive ]

    [#list environment as name,value]
        [#local prefix = occurrence.Core.Component.Name?upper_case + "_"]
        [#if name?starts_with(prefix)]
            [#local attributes += { name?remove_beginning(prefix) : value } ]
        [/#if]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "external" : {
                    "Id" : formatResourceId(SHARED_EXTERNAL_RESOURCE_TYPE, core.Id),
                    "Type" : SHARED_EXTERNAL_RESOURCE_TYPE,
                    "Deployed" : true
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

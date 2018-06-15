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
                "Name" : "Authentication",
                "Default" : "IP"
            },
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
                "Name" : "Encrypted",
                "Default" : false
            },
            {
                "Name" : "Snapshot",
                "Children" : [
                    {
                        "Name" : "Hour",
                        "Default" : ""
                    }
                ]
            },
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    }]

[#function getESState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local esId = formatResourceId(AWS_ES_RESOURCE_TYPE, core.Id)]

    [#return
        {
            "Resources" : {
                "es" : { 
                    "Id" : esId,
                    "Name" : core.Name,
                    "Type" : AWS_ES_RESOURCE_TYPE
                },
                "servicerole" : {
                    "Id" : formatDependentRoleId(esId),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "FQDN" : getReference(esId, DNS_ATTRIBUTE_TYPE),
                "AUTH" : solution.Authentication
            },
            "Roles" : {
                "Outbound" : {
                    "default" : "consume",
                    "consume" : esConsumePermission(esId)
                },
                "Inbound" : {
                }
            }
        }
    ]
[/#function]
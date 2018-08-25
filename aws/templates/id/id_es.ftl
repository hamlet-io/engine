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
                "Type" : "string",
                "Values" : ["IP", "SIG4ORIP", "SIG4ANDIP"],
                "Default" : "IP"
            },
            {
                "Name" : "IPAddressGroups",
                "Type" : "array",
                "Mandatory" : true
            },
            {
                "Name" : "AdvancedOptions",
                "Type" : "array",
                "Default" : []
            },
            {
                "Name" : "Version",
                "Type" : "string",
                "Default" : "2.3"
            },
            {
                "Name" : "Encrypted",
                "Type" : "boolean",
                "Default" : false
            },
            {
                "Name" : "Snapshot",
                "Children" : [
                    {
                        "Name" : "Hour",
                        "Type" : "string",
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
    [#local esHostName = getExistingReference(esId, DNS_ATTRIBUTE_TYPE) ]

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
                "REGION" : regionId,
                "AUTH" : solution.Authentication,
                "FQDN" : esHostName,
                "URL" : "https://" + esHostName,
                "KIBANA_URL" : "https://" + esHostName + "/_plugin/kibana/",
                "PORT" : 443
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

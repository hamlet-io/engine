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
        ES_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A managed ElasticSearch instance"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Authentication",
                    "Type" : STRING_TYPE,
                    "Values" : ["IP", "SIG4ORIP", "SIG4ANDIP"],
                    "Default" : "IP"
                },
                {
                    "Names" : "Accounts",
                    "Description" : "A list of accounts which will be permitted to access the ES index",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : [ "_environment" ]
                },
                {
                    "Names" : "IPAddressGroups",
                    "Description" : "A list of IP Address Groups which will be permitted to access the ES index",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "AdvancedOptions",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Version",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Encrypted",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Snapshot",
                    "Children" : [
                        {
                            "Names" : "Hour",
                            "Type" : STRING_TYPE,
                            "Default" : ""
                        }
                    ]
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration + 
                                    [
                                        {
                                            "Names" : "Processor",
                                            "Type" : STRING_TYPE,
                                            "Default" : "default"
                                        }
                                    ]
                },
                {
                    "Names" : "Alerts",
                    "Subobjects" : true,
                    "Children" : alertChildrenConfiguration
                }
            ]
        }
    }]

[#function getESState occurrence baseState]
    [#local core = occurrence.Core]

    [#if core.External!false]
        [#local id = baseState.Attributes["ES_DOMAIN_ARN"]!"" ]
        [#return
            baseState +
            valueIfContent(
                {
                    "Roles" : {
                        "Outbound" : {
                            "default" : "consume",
                            "consume" : esConsumePermission(esId),
                            "datafeed" : esKinesesStreamPermission(esId)
                        },
                        "Inbound" : {
                        }
                    }
                },
                id,
                {
                    "Roles" : {
                        "Inbound" : {},
                        "Outbound" : {}
                    }
                }
            )
        ]
    [/#if]

    [#local solution = occurrence.Configuration.Solution]
    [#local esId = formatResourceId(AWS_ES_RESOURCE_TYPE, core.Id)]
    [#local esHostName = getExistingReference(esId, DNS_ATTRIBUTE_TYPE) ]

    [#return
        {
            "Resources" : {
                "es" : { 
                    "Id" : esId,
                    "Name" : core.ShortFullName,
                    "Type" : AWS_ES_RESOURCE_TYPE,
                    "Monitored" : true
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
                    "consume" : esConsumePermission(esId),
                    "datafeed" : esKinesesStreamPermission(esId)
                },
                "Inbound" : {
                }
            }
        }
    ]
[/#function]

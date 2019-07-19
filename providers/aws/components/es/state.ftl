[#ftl]

[#macro aws_es_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]

    [#if core.External!false]
        [#local esId = baseState.Attributes["ES_DOMAIN_ARN"]!"COTFatal: Could not find ARN" ]
        [#assign componentState =
            baseState +
            valueIfContent(
                {
                    "Resources" : {
                        "es" : {
                            "Id" : esId,
                            "Type" : AWS_ES_RESOURCE_TYPE,
                            "Deployed" : true
                        }
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
                },
                esId,
                {}
            )
        ]

    [#else]

        [#local solution = occurrence.Configuration.Solution]
        [#local esId = formatResourceId(AWS_ES_RESOURCE_TYPE, core.Id)]
        [#local esHostName = getExistingReference(esId, DNS_ATTRIBUTE_TYPE) ]

        [#assign componentState =
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
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
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
    [/#if]
[/#macro]

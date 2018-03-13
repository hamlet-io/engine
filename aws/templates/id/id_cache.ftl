[#-- Cache --]

[#assign CACHE_RESOURCE_TYPE = "cache" ]
[#assign CACHE_SUBNET_GROUP_RESOURCE_TYPE = "cacheSubnetGroup" ]
[#assign CACHE_PARAMETER_GROUP_RESOURCE_TYPE = "cacheParameterGroup" ]

[#assign CACHE_COMPONENT_TYPE = "cache" ]

[#assign componentConfiguration +=
    {
        CACHE_COMPONENT_TYPE : [
            {
                "Name" : "Engine",
                "Mandatory" : true
            },
            "EngineVersion",
            "Port",
            {
                "Name" : "Backup",
                "Children" : [
                    {
                        "Name" : "RetentionPeriod",
                        "Default" : ""
                    }
                ]
            }
        ]
}]

[#function getCacheState occurrence]
    [#local core = occurrence.Core]

    [#local id = formatResourceId(CACHE_RESOURCE_TYPE, core.Id) ]

    [#local result =
        {
            "Resources" : {
                "cache" : {
                    "Id" : id,
                    "Name" : core.FullName
                },
                "subnetGroup" : {
                    "Id" : formatResourceId(CACHE_SUBNET_GROUP_RESOURCE_TYPE, core.Id)
                },
                "parameterGroup" : {
                    "Id" : formatResourceId(CACHE_PARAMETER_GROUP_RESOURCE_TYPE, core.Id)
                }
            },
            "Attributes" : {
                "FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                "PORT" : getExistingReference(id, PORT_ATTRIBUTE_TYPE),
                "URL" :
                    valueIfTrue(
                        "redis://",
                        occurrence.Configuration.Engine == "redis",
                        "memcached://"
                    ) +
                    getExistingReference(id, DNS_ATTRIBUTE_TYPE) +
                    ":" +
                    getExistingReference(id, PORT_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]
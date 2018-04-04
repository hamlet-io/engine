[#-- Cache --]

[#-- Resources --]
[#assign AWS_CACHE_RESOURCE_TYPE = "cache" ]
[#assign AWS_CACHE_SUBNET_GROUP_RESOURCE_TYPE = "cacheSubnetGroup" ]
[#assign AWS_CACHE_PARAMETER_GROUP_RESOURCE_TYPE = "cacheParameterGroup" ]

[#-- Components --]
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

    [#local id = formatResourceId(AWS_CACHE_RESOURCE_TYPE, core.Id) ]

    [#local result =
        {
            "Resources" : {
                "cache" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Type" : AWS_CACHE_RESOURCE_TYPE
                },
                "subnetGroup" : {
                    "Id" : formatResourceId(AWS_CACHE_SUBNET_GROUP_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_CACHE_SUBNET_GROUP_RESOURCE_TYPE
                },
                "parameterGroup" : {
                    "Id" : formatResourceId(AWS_CACHE_PARAMETER_GROUP_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_CACHE_PARAMETER_GROUP_RESOURCE_TYPE
                },
                "secGroup" : {
                    "Id" : formatSecurityGroupId(core.Id),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "ENGINE" : occurrence.Configuration.Engine,
                "FQDN"  : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
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
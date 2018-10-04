[#-- Cache --]

[#-- Resources --]
[#assign AWS_CACHE_RESOURCE_TYPE = "cache" ]
[#assign AWS_CACHE_SUBNET_GROUP_RESOURCE_TYPE = "cacheSubnetGroup" ]
[#assign AWS_CACHE_PARAMETER_GROUP_RESOURCE_TYPE = "cacheParameterGroup" ]

[#-- Components --]
[#assign CACHE_COMPONENT_TYPE = "cache" ]

[#assign componentConfiguration +=
    {
        CACHE_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "Managed in-memory cache services"
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
                    "Name" : "Engine",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Name" : "EngineVersion",
                    "Type" : STRING_TYPE
                },
                {
                    "Name" : "Port",
                    "Type" : STRING_TYPE
                },
                {
                    "Name" : "Backup",
                    "Children" : [
                        {
                            "Name" : "RetentionPeriod",
                            "Type" : STRING_TYPE,
                            "Default" : ""
                        }
                    ]
                }
            ]
        }
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
                "sg" : {
                    "Id" : formatDependentSecurityGroupId(id),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "ENGINE" : occurrence.Configuration.Solution.Engine,
                "FQDN"  : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                "PORT" : getExistingReference(id, PORT_ATTRIBUTE_TYPE),
                "URL" :
                    valueIfTrue(
                        "redis://",
                        occurrence.Configuration.Solution.Engine == "redis",
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
[#-- ELB --]

[#-- Resources --]
[#assign AWS_ELB_RESOURCE_TYPE = "elb" ]

[#function formatELBId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_ELB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]


[#-- Components --]
[#assign ELB_COMPONENT_TYPE = "elb"]

[#assign componentConfiguration +=
    {
        ELB_COMPONENT_TYPE : [
            {
                "Name" : "PortMappings",
                "Default" : [ "https", "http" ]
            },
            {
                "Name" : "HealthCheck",
                "Children" : [
                    {
                        "Name" : "Protocol",
                        "Default" : ""
                    },
                    {
                        "Name" : "Path",
                        "Default" : ""
                    },
                    {
                        "Name" : "HealthyThreshold",
                        "Default" : ""
                    },
                    {
                        "Name" : "UnhealthyThreshold",
                        "Default" : ""
                    },
                    {
                        "Name" : "Interval",
                        "Default" : ""
                    },
                    {
                        "Name" : "Timeout",
                        "Default" : ""
                    }
                ]
            },
            {
                "Name" : "Logs",
                "Default" : false
            }
        ]
    }]

[#function getELBState occurrence]
    [#local core = occurrence.Core]

    [#local id = formatELBId(core.Tier, core.Component)]

    [#return
        {
            "Resources" : {
                "elb" : { 
                    "Id" : id,
                    "Name" : formatComponentFullName(core.Tier, core.Component),
                    "ShortName" : formatComponentShortFullName(core.Tier, core.Component),
                    "Type" : AWS_ELB_RESOURCE_TYPE
                },
                "secGroup" : { 
                    "Id" : formatSecurityGroupId(core.Id),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
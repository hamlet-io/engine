[#-- ELB --]

[#-- Resources --]
[#assign AWS_ELB_RESOURCE_TYPE = "elb" ]

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

    [#local id = formatResourceId(AWS_ELB_RESOURCE_TYPE, core.Id)]

    [#return
        {
            "Resources" : {
                "lb" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "ShortName" : core.ShortFullName,
                    "Type" : AWS_ELB_RESOURCE_TYPE
                },
                "sg" : {
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
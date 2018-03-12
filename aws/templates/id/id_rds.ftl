[#-- RDS --]

[#assign RDS_RESOURCE_TYPE = "rds" ]
[#assign RDS_SUBNET_GROUP_RESOURCE_TYPE = "rdsSubnetGroup" ]
[#assign RDS_PARAMETER_GROUP_RESOURCE_TYPE = "rdsParameterGroup" ]
[#assign RDS_OPTION_GROUP_RESOURCE_TYPE = "rdsOptionGroup" ]

[#assign RDS_COMPONENT_TYPE = "rds" ]

[#function formatDependentRDSSnapshotId resourceId extensions... ]
    [#return formatDependentResourceId(
                "snapshot",
                resourceId,
                extensions)]
[/#function]

[#assign componentConfiguration +=
    {
        RDS_COMPONENT_TYPE : [
            {
                "Name" : "Engine",
                "Mandatory" : true
            },
            "EngineVersion",
            "Port",
            {
                "Name" : "Encrypted",
                "Default" : false
            },
            { 
                "Name" : "Size",
                "Default" : "20"
            },
            {
                "Name" : "Backup",
                "Children" : [
                    {
                        "Name" : "RetentionPeriod",
                        "Default" : 35
                    },
                    {
                        "Name" : "SnapshotOnDeploy",
                        "Default" : false
                    }
                ]
            },
            "AutoMinorVersionUpgrade"
        ]
}]
    
[#function getRDSState occurrence]
    [#local core = occurrence.Core]

    [#local id = formatResourceId(RDS_RESOURCE_TYPE, core.Id) ]

    [#local result =
        {
            "Resources" : {
                "db" : {
                    "Id" : id,
                    "Name" : core.FullName
                },
                "subnetGroup" : {
                    "Id" : formatResourceId(RDS_SUBNET_GROUP_RESOURCE_TYPE, core.Id)
                },
                "parameterGroup" : {
                    "Id" : formatResourceId(RDS_PARAMETER_GROUP_RESOURCE_TYPE, core.Id)
                },
                "optionGroup" : {
                    "Id" : formatResourceId(RDS_OPTION_GROUP_RESOURCE_TYPE, core.Id)
                }
            },
            "Attributes" : {
                "FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                "PORT" : getExistingReference(id, PORT_ATTRIBUTE_TYPE),
                "NAME" : getExistingReference(id, DATABASENAME_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#list
        (
            credentialsObject[formatComponentShortNameWithType(core.Tier, core.Component)]!
            credentialsObject[formatComponentShortName(core.Tier, core.Component)]!
            {
                "Login" : {
                    "Username" : "Not provided",
                    "Password" : "Not provided"
                }
            }
        ).Login as name,value]
        [#local result +=
            {
              "Attributes" : result.Attributes + { name?upper_case : value }
            }
        ]
    [/#list]
    [#return result ]
[/#function]
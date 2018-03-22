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

[#function formatDependentRDSManualSnapshotId resourceId extensions... ]
    [#return formatDependentResourceId(
                "manualsnapshot",
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
                        "Default" : true
                    }
                ]
            },
            "AutoMinorVersionUpgrade"
        ]
}]
    
[#function getRDSState occurrence]
    [#local core = occurrence.Core]
    [#local id = formatResourceId(RDS_RESOURCE_TYPE, core.Id) ]

    [#local engine = occurrence.Configuration.Engine]
    [#local fqdn = getExistingReference(id, DNS_ATTRIBUTE_TYPE)]
    [#local port = getExistingReference(id, PORT_ATTRIBUTE_TYPE)]
    [#local name = getExistingReference(id, DATABASENAME_ATTRIBUTE_TYPE)]

    [#local login = {} ]
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
        [#local login +=
            { 
                name?upper_case : value 
            }
        ]
    [/#list]

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
                "FQDN" : fqdn,
                "PORT" : port,
                "NAME" : name,
                "USERNAME" : login.USERNAME,
                "PASSWORD" : login.PASSWORD,
                "URL" : engine + "://" + login.USERNAME + ":" + login.PASSWORD + "@" + fqdn + ":" + port + "/" + name 
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]
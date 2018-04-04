[#-- RDS --]

[#assign AWS_RDS_RESOURCE_TYPE = "rds" ]
[#assign AWS_RDS_SUBNET_GROUP_RESOURCE_TYPE = "rdsSubnetGroup" ]
[#assign AWS_RDS_PARAMETER_GROUP_RESOURCE_TYPE = "rdsParameterGroup" ]
[#assign AWS_RDS_OPTION_GROUP_RESOURCE_TYPE = "rdsOptionGroup" ]

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
                "Name" : "GenerateCredentials",
                "Children" : [
                    {
                        "Name" : "Enabled",
                        "Default" : false
                    },
                    {
                        "Name" : "MasterUserName",
                        "Default" : "root"
                    }
                    {
                        "Name" : "CharacterLength",
                        "Default" : 20
                    }
                ]
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
            "AutoMinorVersionUpgrade",
            "DatabaseName"
        ]
}]
    
[#function getRDSState occurrence]
    [#local core = occurrence.Core]
    [#local id = formatResourceId(AWS_RDS_RESOURCE_TYPE, core.Id) ]

    [#local engine = occurrence.Configuration.Engine]
    [#local fqdn = getExistingReference(id, DNS_ATTRIBUTE_TYPE)]
    [#local port = getExistingReference(id, PORT_ATTRIBUTE_TYPE)]
    [#local name = getExistingReference(id, DATABASENAME_ATTRIBUTE_TYPE)]

    [#local login = {} ]
    [#if occurrence.Configuration.GenerateCredentials.Enabled ]
        [#local login += {
            "USERNAME" : occurrence.Configuration.GenerateCredentials.MasterUserName,
            "PASSWORD" : getExistingReference(id, GENERATEDPASSWORD_ATTRIBUTE_TYPE)
        }]
    [#else]
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
    [/#if]

    [#local result =
        {
            "Resources" : {
                "db" : {
                    "Id" : id,
                    "Name" : core.FullName
                },
                "subnetGroup" : {
                    "Id" : formatResourceId(AWS_RDS_SUBNET_GROUP_RESOURCE_TYPE, core.Id)
                },
                "parameterGroup" : {
                    "Id" : formatResourceId(AWS_RDS_PARAMETER_GROUP_RESOURCE_TYPE, core.Id)
                },
                "optionGroup" : {
                    "Id" : formatResourceId(AWS_RDS_OPTION_GROUP_RESOURCE_TYPE, core.Id)
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
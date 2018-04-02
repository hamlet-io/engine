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
    [#local id = formatResourceId(RDS_RESOURCE_TYPE, core.Id) ]

    [#local engine = occurrence.Configuration.Solution.Engine]
    [#local fqdn = getExistingReference(id, DNS_ATTRIBUTE_TYPE)]
    [#local port = getExistingReference(id, PORT_ATTRIBUTE_TYPE)]
    [#local name = getExistingReference(id, DATABASENAME_ATTRIBUTE_TYPE)]

    [#if occurrence.Solution.GenerateCredentials.Enabled ]
        [#local masterUsername = occurrence.Configuration.GenerateCredentials.MasterUserName ]
        [#local masterPassword = getExistingReference(id, GENERATEDPASSWORD_ATTRIBUTE_TYPE) ]
    [#else]
        [#local masterUsername = getOccurrenceSettingValue(occurrence, "MASTER_USERNAME") ]
        [#local masterPassword = getOccurrenceSettingValue(occurrence, "MASTER_PASSWORD") ]
    [/#if]

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
                "USERNAME" : masterUsername,
                "PASSWORD" : masterPassword,
                "URL" : engine + "://" + masterUsername + ":" + masterPassword + "@" + fqdn + ":" + port + "/" + name 
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]
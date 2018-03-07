[#-- RDS --]

[#assign RDS_RESOURCE_TYPE = "rds" ]
[#assign RDS_SUBNET_GROUP_RESOURCE_TYPE = "rdsSubnetGroup" ]
[#assign RDS_PARAMETER_GROUP_RESOURCE_TYPE = "rdsParameterGroup" ]
[#assign RDS_OPTION_GROUP_RESOURCE_TYPE = "rdsOptionGroup" ]

[#function formatRDSId tier component extensions...]
    [#return formatComponentResourceId(
                RDS_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSSubnetGroupId tier component extensions...]
    [#return formatComponentResourceId(
                RDS_SUBNET_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSParameterGroupId tier component extensions...]
    [#return formatComponentResourceId(
                RDS_PARAMETER_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSOptionGroupId tier component extensions...]
    [#return formatComponentResourceId(
                RDS_OPTION_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatDependentRDSSnapshotId resourceId extensions... ]
    [#return formatDependentResourceId(
                "snapshot",
                resourceId,
                extensions)]
[/#function]

[#assign componentConfiguration +=
    {
        "rds" : [
            "Engine",
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

    [#local id = formatRDSId(core.Tier, core.Component, occurrence)]

    [#local result =
        {
            "Resources" : {
                "db" : {
                    "Id" : id
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
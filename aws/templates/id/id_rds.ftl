[#-- RDS --]

[#-- Resources --]
[#assign AWS_RDS_RESOURCE_TYPE = "rds" ]
[#assign AWS_RDS_SUBNET_GROUP_RESOURCE_TYPE = "rdsSubnetGroup" ]
[#assign AWS_RDS_PARAMETER_GROUP_RESOURCE_TYPE = "rdsParameterGroup" ]
[#assign AWS_RDS_OPTION_GROUP_RESOURCE_TYPE = "rdsOptionGroup" ]

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


[#-- Components --]
[#assign RDS_COMPONENT_TYPE = "rds" ]

[#assign componentConfiguration +=
    {
        RDS_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A managed SQL database instance"
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
                    "Names" : "Engine",
                    "Mandatory" : true
                },
                {
                    "Names" : "EngineVersion",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Port",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Encrypted",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "GenerateCredentials",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "MasterUserName",
                            "Type" : STRING_TYPE,
                            "Default" : "root"
                        },
                        {
                            "Names" : "CharacterLength",
                            "Type" : NUMBER_TYPE,
                            "Default" : 20
                        },
                        {
                            "Names" : "EncryptionScheme",
                            "Type" : STRING_TYPE,
                            "Values" : ["base64"],
                            "Default" : ""
                        }
                    ]
                },
                {
                    "Names" : "Size",
                    "Type" : NUMBER_TYPE,
                    "Default" : 20
                },
                {
                    "Names" : "Backup",
                    "Children" : [
                        {
                            "Names" : "RetentionPeriod",
                            "Type" : NUMBER_TYPE,
                            "Default" : 35
                        },
                        {
                            "Names" : "SnapshotOnDeploy",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "DeleteAutoBackups",
                            "Type" : BOOLEAN_TYPE,
                            "Description" : "Delete automated snapshots when the instance is deleted",
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "AutoMinorVersionUpgrade",
                    "Type" : BOOLEAN_TYPE
                },
                {
                    "Names" : "DatabaseName",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "DBParameters",
                    "Type" : OBJECT_TYPE,
                    "Default" : {}
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                },
                {
                    "Names" : "Hibernate",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "StartUpMode",
                            "Type" : STRING_TYPE,
                            "Values" : ["restore", "replace"],
                            "Default" : "restore"
                        }
                    ]
                }
            ]
    }
}]

[#function getRDSState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_RDS_RESOURCE_TYPE, core.Id) ]

    [#local engine = occurrence.Configuration.Solution.Engine]
    [#local fqdn = getExistingReference(id, DNS_ATTRIBUTE_TYPE)]
    [#local port = getExistingReference(id, PORT_ATTRIBUTE_TYPE)]
    [#local name = getExistingReference(id, DATABASENAME_ATTRIBUTE_TYPE)]
    [#local region = getExistingReference(id, REGION_ATTRIBUTE_TYPE)]
    [#local encryptionScheme = (solution.GenerateCredentials.EncryptionScheme)?has_content?then(
                        solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
                        "" )]

    [#if solution.GenerateCredentials.Enabled ]
        [#local masterUsername = solution.GenerateCredentials.MasterUserName ]
        [#local masterPassword = getExistingReference(id, GENERATEDPASSWORD_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme) ]
        [#local url = getExistingReference(id, URL_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme) ]
    [#else]
        [#-- don't flag an error if credentials missing but component is not enabled --]
        [#local masterUsername = getOccurrenceSettingValue(occurrence, "MASTER_USERNAME", !solution.Enabled) ]
        [#local masterPassword = getOccurrenceSettingValue(occurrence, "MASTER_PASSWORD", !solution.Enabled) ]
        [#local url = engine + "://" + masterUsername + ":" + masterPassword + "@" + fqdn + ":" + port + "/" + name]
    [/#if]

    [#local result =
        {
            "Resources" : {
                "db" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Type" : AWS_RDS_RESOURCE_TYPE
                },
                "subnetGroup" : {
                    "Id" : formatResourceId(AWS_RDS_SUBNET_GROUP_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_RDS_SUBNET_GROUP_RESOURCE_TYPE
                },
                "parameterGroup" : {
                    "Id" : formatResourceId(AWS_RDS_PARAMETER_GROUP_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_RDS_PARAMETER_GROUP_RESOURCE_TYPE
                },
                "optionGroup" : {
                    "Id" : formatResourceId(AWS_RDS_OPTION_GROUP_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_RDS_OPTION_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "ENGINE" : engine,
                "FQDN" : fqdn,
                "PORT" : port,
                "NAME" : name,
                "USERNAME" : masterUsername,
                "PASSWORD" : masterPassword,
                "INSTANCEID" : core.FullName,
                "REGION" : region
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]
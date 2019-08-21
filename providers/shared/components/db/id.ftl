[#ftl]

[@addComponent
    type=DB_COMPONENT_TYPE
    properties=
        [
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
            },
            {
                "Type" : "Note",
                "Value" : "Major Version Upgrades - When performing a major version upgrade only change the EngineVersion",
                "Severity" : "warning"
            },
            {
                "Type" : "Note",
                "Value" : "AWS RDS - Major Version - Follow this guide to select the right version when performing a major version update - https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.Upgrading.html",
                "Severity" : "information"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Mandatory" : true
            },
            {
                "Names" : "EngineVersion",
                "Type" : STRING_TYPE,
                "Mandatory" : true
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
                    },
                    {
                        "Names" : "DeletionPolicy",
                        "Type" : STRING_TYPE,
                        "Values" : [ "Snapshot", "Delete", "Retain" ],
                        "Default" : "Snapshot"
                    },
                    {
                        "Names" : "UpdateReplacePolicy",
                        "Type" : STRING_TYPE,
                        "Values" : [ "Snapshot", "Delete", "Retain" ],
                        "Default" : "Snapshot"
                    }
                ]
            },
            {
                "Names" : "AllowMajorVersionUpgrade",
                "Description" : "If the EngineVersion paramter is updated allow for major version updates to run",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
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
                "Children" :
                    [
                        {
                            "Names" : "Processor",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Alert",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
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
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "AlwaysCreateFromSnapshot",
                "Description" : "Always create the database from a snapshot",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            }
        ]
/]

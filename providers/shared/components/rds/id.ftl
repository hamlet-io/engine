[#ftl]

[@addComponent
    type=RDS_COMPONENT_TYPE
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

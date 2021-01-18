[#ftl]

[@addComponentDeployment
    type=DB_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=DB_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A managed SQL database instance"
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
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "EngineVersion",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "EngineMinorVersion",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "Port",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : "Encrypted",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "GenerateCredentials",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "MasterUserName",
                        "Types" : STRING_TYPE,
                        "Default" : "root"
                    },
                    {
                        "Names" : "CharacterLength",
                        "Types" : NUMBER_TYPE,
                        "Default" : 20
                    },
                    {
                        "Names" : "EncryptionScheme",
                        "Types" : STRING_TYPE,
                        "Description" : "A prefix appended to link attributes to show encryption status",
                        "Default" : ""
                    }
                ]
            },
            {
                "Names" : "Size",
                "Types" : NUMBER_TYPE,
                "Default" : 20
            },
            {
                "Names" : "Backup",
                "Children" : [
                    {
                        "Names" : "RetentionPeriod",
                        "Types" : NUMBER_TYPE,
                        "Default" : 35
                    },
                    {
                        "Names" : "SnapshotOnDeploy",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "DeleteAutoBackups",
                        "Types" : BOOLEAN_TYPE,
                        "Description" : "Delete automated snapshots when the instance is deleted",
                        "Default" : true
                    },
                    {
                        "Names" : "DeletionPolicy",
                        "Types" : STRING_TYPE,
                        "Values" : [ "Snapshot", "Delete", "Retain" ],
                        "Default" : "Snapshot"
                    },
                    {
                        "Names" : "UpdateReplacePolicy",
                        "Types" : STRING_TYPE,
                        "Values" : [ "Snapshot", "Delete", "Retain" ],
                        "Default" : "Snapshot"
                    }
                ]
            },
            {
                "Names" : "AllowMajorVersionUpgrade",
                "Description" : "If the EngineVersion paramter is updated allow for major version updates to run",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AutoMinorVersionUpgrade",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "DatabaseName",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "DBParameters",
                "Types" : OBJECT_TYPE,
                "Default" : {}
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Processor",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Alert",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Security",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Hibernate",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "StartUpMode",
                        "Types" : STRING_TYPE,
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
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "AlwaysCreateFromSnapshot",
                "Description" : "Always create the database from a snapshot",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Monitoring",
                "Description" : "Monitoring configuration options",
                "Children" : [
                    {
                        "Names" : "QueryPerformance",
                        "Description" : "Enable monitoring database query performance",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Names" : "RetentionPeriod",
                                "Description" : "How long to keep data for ( days )",
                                "Values" : [ 7, 731 ],
                                "Types" : NUMBER_TYPE,
                                "Default" : 7
                            }
                        ]
                    },
                    {
                        "Names" : "DetailedMetrics",
                        "Description" : "Enables detailed metric collection from the database host",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Names" : "CollectionInterval",
                                "Description" : "Metric Collection interval ( seconds )",
                                "Types" : NUMBER_TYPE,
                                "Values" : [ 0, 1, 5, 10, 15, 30, 60 ],
                                "Default" : 60
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "Cluster",
                "Description" : "Cluster specific configuration when using a clustered database engine",
                "Children" : [
                    {
                        "Names" : "ScalingPolicies",
                        "Subobjects" : true,
                        "Children" : scalingPolicyChildrenConfiguration
                    },
                    {
                        "Names" : "Parameters",
                        "Description" : "Cluster level database parameters",
                        "Subobjects" : true,
                        "Children" : [
                            {
                                "Names" : "Name",
                                "Types" : STRING_TYPE,
                                "Mandatory" : true
                            },
                            {
                                "Names" : "Value",
                                "Types" : [ STRING_TYPE, NUMBER_TYPE, BOOLEAN_TYPE],
                                "Mandatory" : true
                            }
                        ]
                    }
                ]
            }
        ]
/]

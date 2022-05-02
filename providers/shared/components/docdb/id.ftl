[#ftl]

[@addComponent
    type=DOCDB_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A managed NoSQL database instance"
            }
        ]
    attributes=
        [
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
                "Names" : "rootCredential:Source",
                "Description" : "The source of the root credentials used in the database",
                "Types" : STRING_TYPE,
                "Values" : [ "Generated", "SecretStore", "Settings" ],
                "Default" : "Settings"
            },
            {
                "Names" : [ "rootCredential:Generated", "GenerateCredentials" ],
                "Description" : "Generate credentials and store them as an encrypted string",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : [ "Username", "MasterUserName" ],
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
                "Names" : "rootCredential:SecretStore",
                "Description" : "Use a secret store to manage the root credentials",
                "Children" : [
                    {
                        "Names" : "Username",
                        "Types" : STRING_TYPE,
                        "Default" : "root"
                    },
                    {
                        "Names" : "UsernameAttribute",
                        "Description" : "The attribute of the username to store in the secret",
                        "Types" : STRING_TYPE,
                        "Default" : "username"
                    },
                    {
                        "Names" : "PasswordAttribute",
                        "Description" : "The attribute of the password to store in the secret",
                        "Types" : STRING_TYPE,
                        "Default" : "password"
                    },
                    {
                        "Names" : "GenerationRequirements",
                        "Description" : "When creating the secret using secretstore the policy for generating the secret",
                        "AttributeSet" : SECRETSTRING_ATTRIBUTESET_TYPE
                    }
                    {
                        "Names" : "Link",
                        "Description" : "A link to a secret or store that will keep the secret",
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    }
                ]
            },
            {
                "Names" : "rootCredential:Settings",
                "Description" : "Store the credentials as settings of the database occurrence",
                "Children" : [
                    {
                        "Names" : "UsernameAttribute",
                        "Description" : "The setting attribute that contains the username",
                        "Types" : STRING_TYPE,
                        "Default" : "MASTER_USERNAME"
                    },
                    {
                        "Names" : "PasswordAttribute",
                        "Description" : "The setting attribute that contains the password",
                        "Types" : STRING_TYPE,
                        "Default" : "MASTER_PASSWORD"
                    }
                ]
            },
            {
                "Names" : "Backup",
                "Children" : [
                    {
                        "Names" : "BackupWindow",
                        "AttributeSet" : BACKUPWINDOW_ATTRIBUTESET_TYPE
                    },
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
                "Names" : "MaintenanceWindow",
                "AttributeSet" : MAINTENANCEWINDOW_ATTRIBUTESET_TYPE
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
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "AlwaysCreateFromSnapshot",
                "Description" : "Always create the database from a snapshot",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Cluster",
                "Description" : "Cluster specific configuration when using a clustered database engine",
                "Children" : [
                    {
                        "Names" : "ScalingPolicies",
                        "SubObjects" : true,
                        "AttributeSet" : SCALINGPOLICY_ATTRIBUTESET_TYPE
                    },
                    {
                        "Names" : "Parameters",
                        "Description" : "Cluster level database parameters",
                        "SubObjects" : true,
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

[@addComponentDeployment
    type=DOCDB_COMPONENT_TYPE
    defaultGroup="solution"
/]

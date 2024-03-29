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
                "Names" : [ "MultiAZ", "MultiZone"],
                "Description" : "Deploy resources to multiple Availablity Zones",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
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
                "Names" : "MaintenanceWindow",
                "AttributeSet" : MAINTENANCEWINDOW_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "AllowMajorVersionUpgrade",
                "Description" : "If the EngineVersion parameter is updated allow for major version updates to run",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AutoMinorVersionUpgrade",
                "Types" : BOOLEAN_TYPE,
                "Default": true
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
                "Names" : "SystemNotifications",
                "SubObjects" : true,
                "AttributeSet" : DB_SYSTEM_EVENT_ATTRIBUTESET_TYPE
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
                "Names" : "Logging",
                "Description" : "Control logging exports from the db instance",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description" : "Is log exporting enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "ExportedLogs",
                        "Description" : "The log files to export - _all will export all logs the engine supports",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "_all" ]
                    }
                ]
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
                                "Default" : true
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
                                "Default" : true
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
    type=DB_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addChildComponent
    type=DB_PROXY_COMPONENT_TYPE
    parent=DB_COMPONENT_TYPE
    childAttribute="Proxies"
    linkAttributes="Proxy"
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A database connection pooling proxy"
            }
        ]
    attributes=[
        {
            "Names" : "Enabled",
            "Description": "Is the proxy enabled",
            "Types": BOOLEAN_TYPE,
            "Default": true
        },
        {
            "Names": "TargetTypes",
            "Description" : "The type of the proxy targets to create based on the avaialble db resources",
            "Types": ARRAY_OF_STRING_TYPE,
            "Values" : [ "ReadWrite", "ReadOnly" ],
            "Default" : [ "ReadWrite" ]
        },
        {
            "Names": "ConnectionBorrowTimeout",
            "Description" : "How long to wait for a connection to be released when no other connections are available",
            "Types": NUMBER_TYPE
        },
        {
            "Names" : "MaxConnectionsPercent",
            "Description" : "The percentage of connections that the proxy can use",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "MaxIdleConnectionsPercent",
            "Description" : "The percentage of idle connections that are kept active",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "AuthorisedUsers",
            "Description" : "Defines the users who can use the Proxy",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Source",
                    "Description" : "The source of the user credentials - Secret = a secret component, DBRoot = the root credentials used on the parent DB",
                    "Values" : ["Secret", "DBRoot"],
                    "Default" : "Secret"
                },
                {
                    "Names" : "Source:Secret",
                    "Children": [
                        {
                            "Names" : "Username",
                            "Description" : "The username if not provided in the secret",
                            "Types" : STRING_TYPE
                        },
                        {
                            "Names" : "Link",
                            "Description" : "A link to the secret that holds the credentials for the db - secret should contain username and password as JSON object",
                            "AttributeSet": LINK_ATTRIBUTESET_TYPE
                        }
                    ]
                }
            ]
        },
        {
            "Names": "InitProxy",
            "Description": "A SQL query for the proxy to run on the startup of a new connection",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
                "Names" : "Profiles",
                "Children": [
                    {
                        "Names" : "Network",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
        },
        {
            "Names" : "Links",
            "SubObjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "IPAddressGroups",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : [ "_localnet" ]
        }
    ]
/]

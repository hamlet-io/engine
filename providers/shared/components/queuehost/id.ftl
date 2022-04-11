[#ftl]

[@addComponent
    type=QUEUEHOST_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Managed message queue hosting"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Values" : [ "rabbitmq" ],
                "Mandatory" : true
            },
            {
                "Names" : "EngineVersion",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : [ "MultiAZ", "MultiZone"],
                "Description" : "Deploy resources to multiple Availablity Zones",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Alert",
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
                "Names" : "Processor",
                "Children" : [
                    {
                        "Names" : "Type",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true
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
                        "Values" : ["replace"],
                        "Default" : "replace"
                    }
                ]
            },
            {
                "Names" : "Alerts",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Encrypted",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "MaintenanceWindow",
                "AttributeSet" : MAINTENANCEWINDOW_ATTRIBUTESET_TYPE
            },
            {
                "Names" : ["AutoMinorVersionUpgrade", "AutoMinorUpgrade"],
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "RootCredentials",
                "Description" : "Secret store configuration for the root credentials",
                "Children" : [
                    {
                        "Names" : "Username",
                        "Types" : STRING_TYPE,
                        "Default" : "root"
                    },
                    {
                        "Names" : "EncryptionScheme",
                        "Types" : STRING_TYPE,
                        "Description" : "A prefix appended to link attributes to show encryption status",
                        "Default" : ""
                    },
                    {
                        "Names" : "Secret",
                        "Children" : secretConfiguration
                    },
                    {
                        "Names" : "SecretStore",
                        "Description" : "A link to the certificate store which will keep the secret",
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=QUEUEHOST_COMPONENT_TYPE
    defaultGroup="solution"
/]

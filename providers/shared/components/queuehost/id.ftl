[#ftl]

[@addComponentDeployment
    type=QUEUEHOST_COMPONENT_TYPE
    defaultGroup="solution"
/]

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
                "Type" : STRING_TYPE,
                "Values" : [ "rabbitmq" ],
                "Mandatory" : true
            },
            {
                "Names" : "EngineVersion",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "IPAddressGroups",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Alert",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Processor",
                "Children" : [
                    {
                        "Names" : "Type",
                        "Type" : STRING_TYPE,
                        "Mandatory" : true
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
                        "Values" : ["replace"],
                        "Default" : "replace"
                    }
                ]
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "Encrypted",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "MaintenanceWindow",
                "Children" : [
                    {
                        "Names" : "DayOfTheWeek",
                        "Type" : STRING_TYPE,
                        "Values" : [
                            "Sunday",
                            "Monday",
                            "Tuesday",
                            "Wednesday",
                            "Thursday",
                            "Friday",
                            "Saturday"
                        ],
                        "Default" : "Sunday"
                    },
                    {
                        "Names" : "TimeOfDay",
                        "Type" : STRING_TYPE,
                        "Default" : "00:00"
                    },
                    {
                        "Names" : "TimeZone",
                        "Type" : STRING_TYPE,
                        "Default" : "UTC"
                    }
                ]
            },
            {
                "Names" : "AutoMinorUpgrade",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "RootCredentials",
                "Description" : "Secret store configuration for the root credentials",
                "Children" : [
                    {
                        "Names" : "Username",
                        "Type" : STRING_TYPE,
                        "Default" : "root"
                    },
                    {
                        "Names" : "EncryptionScheme",
                        "Type" : STRING_TYPE,
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
                        "Children"  : linkChildrenConfiguration
                    }
                ]
            }
        ]
/]

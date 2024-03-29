[#ftl]

[@addComponent
    type=DIRECTORY_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A managed directory services instance"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Values" : [ "Simple", "ActiveDirectory" ],
                "Mandatory" : true
            },
            {
                "Names" : "Hostname" ,
                "Description": "FQDN for the Directory Service",
                "AttributeSet" : CERTIFICATE_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : "ShortName",
                "Types" : STRING_TYPE,
                "Description": "NETBIOS name of the Directory Service"
            },
            {
                "Names" : "Size",
                "Types" : STRING_TYPE,
                "Values" : [ "Small", "Large" ],
                "Mandatory" : true
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Logging",
                "Description" : "Manage the logging services enabled for the directory",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
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
                        },
                        {
                            "Names" : "Logging",
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
                        "Values" : ["replace"],
                        "Default" : "replace"
                    }
                ]
            },
            {
                "Names" : "RootCredentials",
                "Description" : "Secret store configuration for the administrator credentials",
                "Children" : [
                    {
                        "Names" : "Username",
                        "Types" : STRING_TYPE,
                        "Default" : "Admin"
                    },
                    {
                        "Names" : "EncryptionScheme",
                        "Types" : STRING_TYPE,
                        "Description" : "A prefix appended to link attributes to show encryption status",
                        "Default" : ""
                    },
                    {
                        "Names" : "Secret",
                        "AttributeSet" : SECRETSOURCE_ATTRIBUTESET_TYPE
                    },
                    {
                        "Names" : [ "Link", "SecretStore" ],
                        "Description" : "A link to a secret or store that will keep the secret",
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=DIRECTORY_COMPONENT_TYPE
    defaultGroup="solution"
/]

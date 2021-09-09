[#ftl]

[@addComponentDeployment
    type=DIRECTORY_COMPONENT_TYPE
    defaultGroup="solution"
/]

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
                "Values" : [ "simple" ],
                "Mandatory" : true
            },
            {
                "Names" : "EnableSSO",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "DsName",
                "Types" : STRING_TYPE,
                "Description": "FQDN for the directory service",
                "Mandatory" : true
            },
            {
                "Names" : "Password",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "ShortName",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "Size",
                "Types" : STRING_TYPE
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

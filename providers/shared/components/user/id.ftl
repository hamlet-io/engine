[#ftl]

[@addComponentDeployment
    type=USER_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addComponent
    type=USER_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A user with permissions on components deployed in the solution"
            }
        ]
    attributes=
        [
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "GenerateCredentials",
                "Children" : [
                    {
                        "Names" : "Formats",
                        "Description" : "The type of credentials to generate - system provides api level access, console is user level access",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Values" : ["system", "console"],
                        "Default"  : [ "system" ]
                    }
                    {
                        "Names" : "EncryptionScheme",
                        "Description" : "A prefix added to the start of the encrypted value to show that it is encrypted",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "CharacterLength",
                        "Description" : "When generating a console credential the length of the password",
                        "Types" : NUMBER_TYPE,
                        "Default" : 20
                    }
                ]
            },
            {
                "Names" : "SSHPublicKeys",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "SettingName",
                        "Types" : STRING_TYPE,
                        "Description"  : "The name of setting where the key is stored"
                    }
                ]
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AsFile",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppData",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppPublic",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            }
        ]
    dependencies=[APIGATEWAY_COMPONENT_TYPE]
/]

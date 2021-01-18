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
                "Subobjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "GenerateCredentials",
                "Children" : [
                    {
                        "Names" : "Formats",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Values" : ["system", "console"],
                        "Default"  : [ "system" ]
                    }
                    {
                        "Names" : "EncryptionScheme",
                        "Types" : STRING_TYPE,
                        "Values" : ["base64"],
                        "Default" : ""
                    },
                    {
                        "Names" : "CharacterLength",
                        "Types" : NUMBER_TYPE,
                        "Default" : 20
                    }
                ]
            },
            {
                "Names" : "SSHPublicKeys",
                "Subobjects" : true,
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

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
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "GenerateCredentials",
                "Children" : [
                    {
                        "Names" : "Formats",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Values" : ["system", "console"],
                        "Default"  : [ "system" ]
                    }
                    {
                        "Names" : "EncryptionScheme",
                        "Type" : STRING_TYPE,
                        "Values" : ["base64"],
                        "Default" : ""
                    },
                    {
                        "Names" : "CharacterLength",
                        "Type" : NUMBER_TYPE,
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
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AsFile",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppData",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppPublic",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            }
        ]
    dependencies=[APIGATEWAY_COMPONENT_TYPE]
/]

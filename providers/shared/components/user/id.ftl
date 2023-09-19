[#ftl]

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
                        "Default" : "base64"
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
                    }
                ]
            },
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Description" : "Limit User access based on IP Address",
                "Default" : []
            },
            {
                "Names": "Username",
                "Children" : [
                    {
                        "Names": "UseIdValues",
                        "Description" : "When formatting the name use the Id of the parts instead of the Name",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "IncludeOrder",
                        "Description" : "The order the includes are added in",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default": [
                            "Product",
                            "Environment",
                            "Segment",
                            "Component",
                            "Instance",
                            "Version",
                            "Name"
                        ]
                    },
                    {
                        "Names" : "Include",
                        "Description": "The parts of the occurrence context to include in the name",
                        "Children" : [
                            {
                                "Names": "Product",
                                "Types": BOOLEAN_TYPE,
                                "Default": true
                            },
                            {
                                "Names": "Environment",
                                "Types": BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names": "Segment",
                                "Types": BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Tier",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Component",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Instance",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Version",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Name",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            }
                        ]
                    },
                    {
                        "Names" : "Name",
                        "Description" : "A custom field used to set a specifc name",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    }
                ]
            }
        ]
    dependencies=[APIGATEWAY_COMPONENT_TYPE]
/]

[@addComponentDeployment
    type=USER_COMPONENT_TYPE
    defaultGroup="application"
/]

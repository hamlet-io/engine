[#-- USER --]

[#-- Components --]
[#assign USER_COMPONENT_TYPE = "user" ]

[#assign componentConfiguration +=
    {
        USER_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A user with permissions on components deployed in the solution"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                { 
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
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
        }
    }]

[#function getUserState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local userId = formatResourceId(AWS_IAM_USER_RESOURCE_TYPE, core.Id) ]
    [#local userArn = getExistingReference(userId, ARN_ATTRIBUTE_TYPE)]

    [#local encryptionScheme = (solution.GenerateCredentials.EncryptionScheme)?has_content?then(
                    solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
                    "" )]

    [#-- Use short full name for user as there is a length limit of 64 chars --]
    [#local result =
        {
            "Resources" : {
                "user" : {
                    "Id" : userId,
                    "Name" : core.ShortFullName,
                    "Type" : AWS_IAM_USER_RESOURCE_TYPE
                },
                "apikey" : {
                    "Id" : formatDependentResourceId(AWS_APIGATEWAY_APIKEY_RESOURCE_TYPE, userId),
                    "Name" : core.FullName,
                    "Type" : AWS_APIGATEWAY_APIKEY_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "USERNAME" : getExistingReference(userId),
                "ARN" : userArn,
                "ACCESS_KEY" : getExistingReference(userId, USERNAME_ATTRIBUTE_TYPE),
                "SECRET_KEY" : getExistingReference(userId, PASSWORD_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme),
                "SES_SMTP_PASSWORD" : getExistingReference(userId, KEY_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme)
            },
            "Roles" : {
                "Inbound" : {
                    "invoke" : {
                        "Principal" : userArn
                    }
                },
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]

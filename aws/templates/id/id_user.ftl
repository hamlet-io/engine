[#-- USER --]

[#-- Components --]
[#assign USER_COMPONENT_TYPE = "user" ]

[#assign componentConfiguration +=
    {
        USER_COMPONENT_TYPE : {
            "Attributes" : [
                {
                    "Name" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                { 
                    "Name" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Name" : "GenerateCredentials",
                    "Children" : [
                        {
                            "Name" : "Formats",
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Values" : ["system", "console"],
                            "Default"  : [ "system" ]
                        }
                        {
                            "Name" : "EncryptionScheme",
                            "Type" : STRING_TYPE,
                            "Values" : ["base64"],
                            "Default" : ""
                        },
                        {
                            "Name" : "CharacterLength",
                            "Type" : NUMBER_TYPE,
                            "Default" : 20
                        }
                    ]
                },
                {
                "Name" : "Permissions",
                "Children" : [
                        {
                            "Name" : "Decrypt",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Name" : "AsFile",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Name" : "AppData",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Name" : "AppPublic",
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
                    "Name" : core.ShortFullName,
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

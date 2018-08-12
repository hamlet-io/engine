[#-- USER --]

[#-- Components --]
[#assign USER_COMPONENT_TYPE = "user" ]

[#assign componentConfiguration +=
    {
        USER_COMPONENT_TYPE : {
            "Attributes" : [
                {
                    "Name" : ["Fragment", "Container"],
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
                            "Default"  : [ "system" ]
                        }
                        {
                            "Name" : "EncryptionScheme",
                            "Default" : ""
                        },
                        {
                            "Name" : "CharacterLength",
                            "Default" : 20
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
                }
            },
            "Attributes" : {
                "USERNAME" : getExistingReference(userId),
                "ARN" : userArn,
                "ACCESS_KEY" : getExistingReference(userId, USER_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme),
                "SECRET_KEY" : getExistingReference(userId, PASSWORD_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme)
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

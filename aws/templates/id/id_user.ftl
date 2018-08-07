[#-- MOBILENOTIFIER --]

[#-- Components --]
[#assign USER_COMPONENT_TYPE = "user" ]

[#assign componentConfiguration +=
    {
        USER_COMPONENT_TYPE : {
            "Attributes" : [
                { 
                    "Name" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Name" : "Type",
                    "Default" : "system"
                },
                {
                    "Name" : "GenerateCredentials",
                    "Children" : [
                        {
                            "Name" : "EncryptionScheme",
                            "Default" : "base64"
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
                "ARN" : userArn
            },
            "Roles" : {
                "Inbound" : {
                    "invoke" : {
                        "Principal" : userArn
                    }
                }
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]

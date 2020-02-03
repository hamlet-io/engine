[#ftl]

[#macro aws_user_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local userId = formatResourceId(AWS_IAM_USER_RESOURCE_TYPE, core.Id) ]
    [#local userArn = getExistingReference(userId, ARN_ATTRIBUTE_TYPE)]

    [#local encryptionScheme = (solution.GenerateCredentials.EncryptionScheme)?has_content?then(
                    solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
                    "" )]

    [#-- Use short full name for user as there is a length limit of 64 chars --]
    [#assign componentState =
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
[/#macro]

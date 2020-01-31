[#ftl]

[#macro aws_federatedrole_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]

    [#local identityPoolId = formatResourceId(AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE, core.Id)]
    [#local identityPoolName = replaceAlphaNumericOnly(core.FullName, "X") ]

    [#assign componentState =
        {
            "Resources" : {
                "identitypool" : {
                    "Id" : identityPoolId,
                    "Name" : identityPoolName,
                    "Type" : AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE
                },
                "rolemapping" : {
                    "Id" : formatResourceId(AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE, core.Id ),
                    "Type" : AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "ID" : getExistingReference(identityPoolId),
                "NAME" : identityPoolName
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]

[/#macro]

[#macro aws_federatedroleassignment_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]

    [#assign componentState =
        {
            "Resources" : {
                "role" : {
                    "Id" : formatResourceId(AWS_IAM_ROLE_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]
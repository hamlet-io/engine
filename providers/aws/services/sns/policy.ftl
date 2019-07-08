[#ftl]

[#function getSnsStatement actions id="" principals="" conditions=""]
    [#local result = [] ]
    [#if id?has_content]
        [#local result +=
            [
                getPolicyStatement(
                    actions,
                    getReference(id, ARN_ATTRIBUTE_TYPE),
                    principals,
                    conditions)
            ]
        ]
    [#else]
        [#local result +=
            [
                getPolicyStatement(
                    actions,
                    "*",
                    principals
                    conditions
                )
            ]
        ]
    [/#if]

    [return result]
[/#function]

[#function snsAdminPermission id=""]
    [#return
        getSnsStatement(
            "sns:*",
            id)]
[/#function]

[#function snsPublishPermission id="" ]
    [#return
        getSnsStatement(
            "sns:publish",
            id)]
[/#function]

[#function snsSMSPermission ]
    [#return
        getPolicyStatement(
            "sns:Publish",
            "*"
        )
    ]
[/#function]


[#function snsS3WritePermission id bucketName="" ]
    [#return
        getSqsStatement(
            "sns:Publish",
            id,
            "*",
            {
                "ArnLike" : {
                    "aws:sourceArn" : "arn:aws:s3:*:*:${bucketName}"
                }
            })]
[/#function]

[#function snsPublishPlatformApplication platformAppName engine topic_prefix ]
    [#return
        [
            getPolicyStatement(
                [
                    "sns:GetPlatformApplicationAttributes",
                    "sns:CreatePlatformEndpoint",
                    "sns:GetEndpointAttributes",
                    "sns:ListEndpointsByPlatformApplication",
                    "sns:SetEndpointAttributes"
                ]
            ),
            getPolicyStatement(
                [
                    "sns:CreateTopic"
                ],
                formatRegionalArn(
                    "sns",
                    topic_prefix + "*"
                )
            ),
            getPolicyStatement(
                [
                    "sns:Publish"
                ],
                [
                    formatRegionalArn(
                        "sns",
                        "app/" + engine + "/" + platformAppName
                    ),
                    formatRegionalArn(
                        "sns",
                        "endpoint/" + engine + "/" + platformAppName + "*"
                    ),
                    formatRegionalArn(
                        "sns",
                        topic_prefix + "*"
                    )
                ]

            )
        ]
    ]
[/#function]
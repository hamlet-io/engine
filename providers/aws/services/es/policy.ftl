[#ftl]

[#function esConsumePermission id  ]
    [#local esArn = getArn(id)]
    [#return
        [
            getPolicyStatement(
                [ "es:ESHttp*"],
                formatRelativePath(esArn, "*")
            )
        ]
    ]
[/#function]


[#function esKinesesStreamPermission id ]
    [#local esArn = getArn(id) ]
    [#return
        [
            getPolicyStatement(
                [
                    "es:DescribeElasticsearchDomain",
                    "es:DescribeElasticsearchDomains",
                    "es:DescribeElasticsearchDomainConfig",
                    "es:ESHttpPost",
                    "es:ESHttpPut",
                    "es:ESHttpGet"
                ],
                [
                    esArn,
                    formatRelativePath(esArn, "*")
                ]
            )
        ]
    ]
[/#function]
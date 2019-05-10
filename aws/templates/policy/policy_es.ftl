[#-- ElasticSearch --]

[#function esConsumePermission id  ]
    [#return
        [
            getPolicyStatement(
                [ "es:ESHttp*"],
                formatESDomainArn(id)
            )
        ]
    ]
[/#function]


[#function esKinesesStreamPermission id ]
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
                    getReference(id, ARN_ATTRIBUTE_TYPE),
                    formatESDomainArn(id)
                ]
            )
        ]
    ]
[/#function]
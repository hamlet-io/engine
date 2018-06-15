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


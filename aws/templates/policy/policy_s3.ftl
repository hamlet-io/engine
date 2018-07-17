[#-- S3 --]

[#function getS3Statement actions bucket key="" object="" principals="" conditions=""]
    [#local s3BucketArn = "arn:aws:s3:::" + (getExistingReference(bucket)?has_content)?then(getExistingReference(bucket),bucket) ]

    [#return
        [
            getPolicyStatement(
                actions,
                [
                    s3BucketArn,
                    s3BucketArn + 
                        key?has_content?then("/" + key,  "") +
                        object?has_content?then("/" + object, "")
                ],
                principals,
                conditions)
        ]
    ]
[/#function]

[#function s3AllPermission bucket key="" object="*" principals="" conditions=""]
    [#return
        getS3Statement(
            [
                "s3:GetObject*",
                "s3:PutObject*",
                "s3:DeleteObject*",
                "s3:RestoreObject*",
                "s3:List*",
                "s3:Abort*"
            ]
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#function s3ConsumePermission bucket key="" object="*" principals="" conditions=""]
    [#return
        getS3Statement(
            [
                "s3:GetObject*",
                "s3:DeleteObject*",
                "s3:List*"
            ]
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#function s3ProducePermission bucket key="" object="*" principals="" conditions="" ]
    [#return 
        getS3Statement(
            [
                "s3:PutObject*",
                "s3:Abort*",
                "s3:List*"
            ],
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#function s3ReadPermission bucket key="" object="*" principals="" conditions=""]
    [#return
        getS3Statement(
            "s3:GetObject*",
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#function s3ReadBucketPermission bucket key="" object="*" principals={"AWS":"*"} conditions=""]
    [#return
        s3ReadPermission(
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]


[#function s3WritePermission bucket key="" object="*" principals="" conditions=""]
    [#return
        getS3Statement(
            "s3:PutObject*",
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#function s3ListPermission bucket key="" object="" principals="" conditions=""]
    [#return
        getS3Statement(
            "s3:List*",
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#function s3ListBucketPermission bucket]
    [#return
        getS3Statement(
            [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            bucket)]
[/#function]



[#function s3ReadBucketACLPermission bucket principals="" conditions=""]
    [#return
        getS3Statement(
            "s3:GetBucketAcl",
            bucket,
            "",
            "",
            principals,
            conditions)]
[/#function]

[#function s3IPAccessCondition cidr allow=true ]
    [#return
        {
            allow?then(
                "IpAddress",
                "NotIPaddress"
            ) : {
                "aws:SourceIp": cidr
            }
        }
    ]
[/#function]
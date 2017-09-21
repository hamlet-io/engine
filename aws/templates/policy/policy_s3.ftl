[#-- S3 --]

[#function getS3Statement actions bucket key="" object="" principals="" conditions=""]
    [#return
        [
            getPolicyStatement(
                actions,
                "arn:aws:s3:::" + 
                    (getKey(bucket)?has_content)?then(getKey(bucket),bucket) +
                    key?has_content?then("/" + key, "") +
                    object?has_content?then("/" + object, ""),
                principals,
                conditions)
        ]
    ]
[/#function]

[#macro s3Statement actions bucket key="" object="" principals="" conditions=""]
    [@policyStatements getS3Statement(actions, bucket, key, object, principals, conditions) /]
[/#macro]

[#function getS3ReadStatement bucket key="" object="*" principals="" conditions=""]
    [#return
        getS3Statement(
            "s3:GetObject*",
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#macro s3ReadStatement bucket key="" object="*" principals="" conditions=""]
    [@policyStatements getS3ReadStatement(bucket, key, object, principals, conditions) /]
[/#macro]

[#function getS3ReadBucketStatement bucket key="" object="*" principals={"AWS":"*"} conditions=""]
    [#return
        getS3ReadStatement(
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#macro s3ReadBucketStatement bucket key="" object="*" principals={"AWS":"*"} conditions=""]
    [@policyStatements getS3ReadBucketStatement(bucket, key, object, principals, conditions) /]
[/#macro]

[#function getS3ConsumeStatement bucket key="" object="*" principals="" conditions=""]
    [#return
        getS3Statement(
            [
                "s3:GetObject*",
                "s3:DeleteObject*"
            ]
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#macro s3ConsumeStatement bucket key="" object="*" principals="" conditions=""]
    [@policyStatements getS3ConsumeStatement(bucket, key, object, principals, conditions) /]
[/#macro]

[#function getS3WriteStatement bucket key="" object="*" principals="" conditions=""]
    [#return
        getS3Statement(
            "s3:PutObject*",
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#macro s3WriteStatement bucket key="" object="*" principals="" conditions=""]
    [@policyStatements getS3WriteStatement(bucket,key, object, principals, conditions) /]
[/#macro]

[#function getS3ListStatement bucket key="" object="" principals="" conditions=""]
    [#return
        getS3Statement(
            "s3:List*",
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#macro s3ListStatement bucket key="" object="" principals="" conditions=""]
    [@policyStatements getS3ListStatement(bucket, key, object, principals, conditions) /]
[/#macro]

[#function getS3ListBucketStatement bucket]
    [#return
        getS3Statement(
            [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            bucket)]
[/#function]

[#macro s3ListBucketStatement bucket]
    [@policyStatements getS3ListBucketStatement(bucket) /]
[/#macro]

[#function getS3AllStatement bucket key="" object="*" principals="" conditions=""]
    [#return
        getS3Statement(
            [
                "s3:GetObject*",
                "s3:PutObject*",
                "s3:DeleteObject*",
                "s3:RestoreObject*",
                "s3:ListMultipart*",
                "s3:AbortMultipart*"
            ]
            bucket,
            key,
            object,
            principals,
            conditions)]
[/#function]

[#macro s3AllStatement bucket key="" object="*" principals="" conditions=""]
    [@policyStatements getS3AllStatement(bucket, key, object, principals, conditions) /]
[/#macro]

[#function getS3ReadBucketACLStatement bucket principals="" conditions=""]
    [#return
        getS3Statement(
            "s3:GetBucketAcl",
            bucket,
            "",
            "",
            principals,
            conditions)]
[/#function]



[#ftl]

[#function cmkDecryptPermission id]
    [#return
        [
            getPolicyStatement(
                "kms:Decrypt",
                getReference(id, ARN_ATTRIBUTE_TYPE))
        ]
    ]
[/#function]

[#function s3EncryptionPermission keyId bucketName bucketPrefix bucketRegion ]
    [#return
        [
            getPolicyStatement(
                [
                    "kms:Decrypt",
                    "kms:GenerateDataKey"
                ],
                getReference(keyId, ARN_ATTRIBUTE_TYPE),
                "",
                {
                    "StringEquals" : {
                        "kms:ViaService" : formatDomainName( "s3", bucketRegion, "amazonaws.com" )
                    },
                    "StringLike" : {
                        "kms:EncryptionContext:aws:s3:arn" : "arn:aws:s3:::" + formatRelativePath(bucketName, bucketPrefix, "*")
                    }
                }
            )
        ]
    ]
[/#function]
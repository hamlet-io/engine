[#-- Standard set of buckets for an account --]
[#if deploymentUnit?contains("s3")]
    [#assign buckets = ["credentials", "code", "registry"]]
    [#if resourceCount > 0],[/#if]
    [#assign bucketCount = 0]
    [#switch accountListMode]
        [#case "definition"]
            [#list buckets as bucket]
                [#if bucketCount > 0],[/#if]
                [#-- Current bucket naming --]
                [#assign bucketName = formatName(bucket, accountDomainQualifier) + "." + accountDomain]
                [#-- Support presence of existing s3 buckets (naming has changed over time) --]
                [#assign bucketName = getKey("s3", "account", bucket)?has_content?then(
                                                                getKey("s3", "account", bucket),
                                                                bucketName)]
                "${formatId("s3", bucket)}" : {
                    "Type" : "AWS::S3::Bucket",
                    "Properties" : {
                        "BucketName" : "${bucketName}",
                        "Tags" : [ 
                            { "Key" : "cot:request", "Value" : "${requestReference}" },
                            { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                            { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                            { "Key" : "cot:account", "Value" : "${accountId}" },
                            { "Key" : "cot:category", "Value" : "${categoryId}" }
                        ]
                    }
                }
                [#assign bucketCount += 1]
            [/#list]
            [#break]
        
        [#case "outputs"]
            "${formatId("domain", "account", "domain")}" : {
                "Value" : "${accountDomain}"
            },
            "${formatId("domain", "account", "qualifier")}" : {
                "Value" : "${accountDomainQualifier}"
            },
            "${formatId("domain", "account", "certificate")}" : {
                "Value" : "${accountDomainCertificateId}"
            },
            [#list buckets as bucket]
                [#if bucketCount > 0],[/#if]
                "${formatId("s3", "account", bucket)}" : {
                    "Value" : { "Ref" : "${formatId("s3", bucket)}" }
                }
                [#assign bucketCount += 1]
            [/#list]
            [#break]

    [/#switch]        
    [#assign resourceCount += 1]
[/#if]


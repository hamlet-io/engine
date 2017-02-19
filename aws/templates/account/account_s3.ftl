[#-- Standard set of buckets for an account --]
[#if slice?contains("s3")]
    [#assign buckets = ["credentials", "code", "registry"]]
    [#if resourceCount > 0],[/#if]
    [#assign bucketCount = 0]
    [#switch accountListMode]
        [#case "definition"]
            [#list buckets as bucket]
                [#if bucketCount > 0],[/#if]
                [#-- Current bucket naming --]
                [#assign bucketName = bucket + accountDomainQualifier + "." + accountDomain]
                [#-- Support presence of existing s3 buckets (naming has changed over time) --]
                [#assign bucketName = getKey("s3XaccountX" + bucket)!bucketName]
                "s3X${bucket}" : {
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
            "domainXaccountXdomain" : {
                "Value" : "${accountDomain}"
            },
            "domainXaccountXqualifier" : {
                "Value" : "${accountDomainQualifier}"
            },
            "domainXaccountXcertificate" : {
                "Value" : "${accountDomainCertificateId}"
            },
            [#list buckets as bucket]
                [#if bucketCount > 0],[/#if]
                "s3XaccountX${bucket}" : {
                    "Value" : { "Ref" : "s3X${bucket}" }
                }
                [#assign bucketCount += 1]
            [/#list]
            [#break]

    [/#switch]        
    [#assign resourceCount += 1]
[/#if]


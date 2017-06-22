[#-- Standard set of buckets for an account --]
[#if deploymentUnit?contains("s3")]
    [#assign buckets = ["credentials", "code", "registry"]]
    [#switch accountListMode]
        [#case "definition"]
            [#list buckets as bucket]
            
                [#-- TODO: Should be using formatAccountS3Id() not formatS3Id() --]
                [#assign s3Id = formatS3Id(bucket)]

                [@checkIfResourcesCreated /]
                [#-- Current bucket naming --]
                [#assign bucketName = formatName(bucket, accountDomainQualifier) + "." + accountDomain]
                [#-- Support presence of existing s3 buckets (naming has changed over time) --]
                [#assign bucketName = getKey("s3", "account", bucket)?has_content?then(
                                                                getKey("s3", "account", bucket),
                                                                bucketName)]
                "${s3Id}" : {
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
                [@resourcesCreated /]
            [/#list]
            [#break]
        
        [#case "outputs"]
            "${formatAccountDomainId()}" : {
                "Value" : "${accountDomain}"
            },
            "${formatAccountDomainQualifierId()}" : {
                "Value" : "${accountDomainQualifier}"
            },
            "${formatAccountDomainCertificateId()}" : {
                "Value" : "${accountDomainCertificateId}"
            }
            [#list buckets as bucket]
                [#-- TODO: Should be using s3Id not formatAccountS3Id(bucket) --]
                ,"${formatAccountS3Id(bucket)}" : {
                    "Value" : { "Ref" : "${formatS3Id(bucket)}" }
                }
            [/#list]
            [@resourcesCreated /]
            [#break]

    [/#switch]        
[/#if]


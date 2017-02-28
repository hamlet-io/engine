[#if deploymentUnit?contains("shared")]
    [#assign arg1 = "domain"]
    [#assign arg2 = "product"]
    [#switch productListMode]
        [#case "definition"]
            [#if (regionId == productRegionId) && (blueprintObject.Tiers["shared"].Components)??]
                [#list blueprintObject.Tiers["shared"].Components?values as component]
                    [#if component?is_hash]
                        [#if component.S3??]
                            [#assign s3 = component.S3]
                            [#if resourceCount > 0],[/#if]
                            [#-- Current bucket naming --]
                            [#if s3.Name != "S3"]
                                [#assign bucketName = s3.Name + productDomainQualifier + "." + productDomain]
                            [#else]
                                [#assign bucketName = component.Name + productDomainQualifier + "." + productDomain]
                            [/#if]
                            [#-- Support presence of existing s3 buckets (naming has changed over time) --]
                            [#assign bucketName = getKey("s3", arg2, component.Id)!bucketName]
                            "${formatId("s3", component.Id)}" : {
                                "Type" : "AWS::S3::Bucket",
                                "Properties" : {
                                    "BucketName" : "${bucketName}",
                                    "Tags" : [
                                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                                        { "Key" : "cot:account", "Value" : "${accountId}" },
                                        { "Key" : "cot:product", "Value" : "${productId}" },
                                        { "Key" : "cot:category", "Value" : "${categoryId}" }
                                    ]
                                    [#if s3.Lifecycle??]
                                        ,"LifecycleConfiguration" : {
                                            "Rules" : [
                                                {
                                                    "Id" : "default",
                                                    [#if s3.Lifecycle.Expiration??]
                                                        "ExpirationInDays" : ${s3.Lifecycle.Expiration},
                                                    [/#if]
                                                    "Status" : "Enabled"
                                                }
                                            ]
                                        }
                                    [/#if]
                                }
                            }
                            [#assign resourceCount += 1]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
            [#break]

        [#case "outputs"]
            [#if (regionId == productRegionId)]
                [#if resourceCount > 0],[/#if]
                "${formatId(arg1, arg2, "domain")}" : {
                    "Value" : "${productDomain}"
                },
                "${formatId(arg1, arg2, "qualifier")}" : {
                    "Value" : "${productDomainQualifier}"
                },
                "${formatId(arg1, arg2, "certificate")}" : {
                    "Value" : "${productDomainCertificateId}"
                }
                [#if (regionId == productRegionId) && (blueprintObject.Tiers["shared"].Components)??]
                    [#list blueprintObject.Tiers["shared"].Components?values as component]
                        [#if component?is_hash]
                            [#if component.S3??]
                                [#assign s3 = component.S3]
                                "${formatId("s3", arg2, component.Id)}" : {
                                    "Value" : { "Ref" : "${formatId("s3", component.Id)}" }
                                }
                            [/#if]
                        [/#if]
                    [/#list]
                [/#if]
                [#assign resourceCount += 1]
            [/#if]
            [#break]

    [/#switch]
[/#if]


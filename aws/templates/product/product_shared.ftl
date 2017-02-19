[#if slice?contains("shared")]
    [#switch productListMode]
        [#case "definition"]
            [#if (regionId == productRegionId) && (blueprintObject.Tiers["shared"].Components)??]
                [#list blueprintObject.Tiers["shared"].Components?values as component]
                    [#if component?is_hash]
                        [#if component.S3??]
                            [#assign s3 = component.S3]
                            [#if sliceCount > 0],[/#if]
                            [#-- Current bucket naming --]
                            [#if s3.Name != "S3"]
                                [#assign bucketName = s3.Name + productDomainQualifier + "." + productDomain]
                            [#else]
                                [#assign bucketName = component.Name + productDomainQualifier + "." + productDomain]
                            [/#if]
                            [#-- Support presence of existing s3 buckets (naming has changed over time) --]
                            [#assign bucketName = getKey("s3XproductX" + component.Id)!bucketName]
                            "s3X${component.Id}" : {
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
                            [#assign sliceCount += 1]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
            [#break]

        [#case "outputs"]
            [#if (regionId == productRegionId)]
                [#if sliceCount > 0],[/#if]
                "domainXproductXdomain" : {
                    "Value" : "${productDomain}"
                }
                ,"domainXproductXqualifier" : {
                    "Value" : "${productDomainQualifier}"
                }
                "domainXproductXcertificate" : {
                    "Value" : "${productDomainCertificateId}"
                }
                [#if (regionId == productRegionId) && (blueprintObject.Tiers["shared"].Components)??]
                    [#list blueprintObject.Tiers["shared"].Components?values as component]
                        [#if component?is_hash]
                            [#if component.S3??]
                                [#assign s3 = component.S3]
                                ,"s3XproductX${component.Id}" : {
                                    "Value" : { "Ref" : "s3X${component.Id}" }
                                }
                            [/#if]
                        [/#if]
                    [/#list]
                [/#if]
                [#assign sliceCount += 1]
            [/#if]
            [#break]

    [/#switch]
[/#if]


[#ftl]
[#-- Standard inputs --]
[#assign blueprintObject = blueprint?eval]
[#assign credentialsObject = credentials?eval]
[#assign appSettingsObject = appsettings?eval]
[#assign stackOutputsObject = stackOutputs?eval]

[#-- High level objects --]
[#assign tenantObject = blueprintObject.Tenant]
[#assign accountObject = blueprintObject.Account]

[#-- Reference data --]
[#assign regions = blueprintObject.Regions]
[#assign categories = blueprintObject.Categories]

[#-- Reference Objects --]
[#assign regionId = accountRegion]
[#assign regionObject = regions[regionId]]
[#assign categoryId = "alm"]
[#assign categoryObject = categories[categoryId]]

[#-- Key ids/names --]
[#assign tenantId = tenantObject.Id]
[#assign accountId = accountObject.Id]
[#assign accountName = accountObject.Name]

[#-- Domains --]
[#assign accountDomainStem = accountObject.Domain.Stem]
[#assign accountDomainBehaviour = (accountObject.Domain.AccountBehaviour)!""]
[#assign accountDomainCertificateId = accountObject.Domain.Certificate.Id]
[#switch accountDomainBehaviour]
    [#case "accountInDomain"]
        [#assign accountDomain = accountName + "." + accountDomainStem]
        [#assign accountDomainQualifier = ""]
        [#assign accountDomainCertificateId = accountDomainCertificateId + "-" + accountId]
        [#break]
    [#case "naked"]
        [#assign accountDomain = accountDomainStem]
        [#assign accountDomainQualifier = ""]
        [#break]
    [#case "accountInHost"]
    [#default]
        [#assign accountDomain = accountDomainStem]
        [#assign accountDomainQualifier = "-" + accountName]
        [#break]
[/#switch]
[#assign accountDomainCertificateId = accountDomainCertificateId?replace("-","X")]

[#assign buckets = ["credentials", "code"]]

[#-- Get stack output --]
[#function getKey key]
    [#list stackOutputsObject as pair]
        [#if pair.OutputKey==key]
            [#return pair.OutputValue]
        [/#if]
    [/#list]
[/#function]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [#assign sliceCount = 0]
        [#if slice?contains("s3")]
            [#-- Standard S3 buckets --]
            [#if sliceCount > 0],[/#if]
            [#list buckets as bucket]
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
                [#if !(bucket == buckets?last)],[/#if]
            [/#list]
            [#assign sliceCount = sliceCount + 1]
        [/#if]
        
        [#if slice?contains("cert")]
            [#-- Generate certificate --]
            [#if sliceCount > 0],[/#if]
            "certificate" : {
                "Type" : "AWS::CertificateManager::Certificate",
                "Properties" : {
                    "DomainName" : "*.${accountDomain}",
                    "DomainValidationOptions" : [
                        {
                            "DomainName" : "*.${accountDomain}",
                            "ValidationDomain" : "${tenantObject.Domain.Validation}"
                        }
                    ]
                }
            }
            [#assign sliceCount = sliceCount + 1]
        [/#if]        
    },
    "Outputs" : {
        [#assign sliceCount = 0]
        [#if slice?contains("s3")]
            [#if sliceCount > 0],[/#if]
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
                "s3XaccountX${bucket}" : {
                    "Value" : { "Ref" : "s3X${bucket}" }
                }
                [#if !(bucket == buckets?last)],[/#if]
            [/#list]
            [#assign sliceCount = sliceCount + 1]
        [/#if]
        
        [#if slice?contains("cert")]
            [#if sliceCount > 0],[/#if]
            "certificateX${accountDomainCertificateId}" : {
                "Value" : { "Ref" : "certificate" }
            }
            [#assign sliceCount = sliceCount + 1]
        [/#if]
        
    }
}



[#-- Standard set of buckets for an account --]
[#if deploymentUnit?contains("s3")]

    [@cfTemplateOutput
        mode=accountListMode
        id=formatAccountDomainId()
        value=accountDomain
    /]
        
    [@cfTemplateOutput
        mode=accountListMode
        id=formatAccountDomainQualifierId()
        value=accountDomainQualifier
    /]

    [@cfTemplateOutput
        mode=accountListMode
        id=formatAccountDomainCertificateId()
        value=accountDomainCertificateId
    /]
    
    [#assign buckets = ["credentials", "code", "registry"]]
    [#list buckets as bucket]
    
        [#-- TODO: Should be using formatAccountS3Id() not formatS3Id() --]
        [#-- TODO: Remove alternate id parameter below when TODO addressed --]
        
        [#assign existingName = getExistingReference(formatAccountS3Id(bucket))]
        [@createS3bucket
            mode=accountListMode
            id=formatS3Id(bucket)
            name=
                existingName?has_content?then(
                    existingName,
                    formatHostDomainName(
                        [
                            bucket,
                            accountDomainQualifier
                        ],
                        accountdomain))
            alternateId=formatAccountS3Id(bucket)
        /]
    [/#list]
[/#if]


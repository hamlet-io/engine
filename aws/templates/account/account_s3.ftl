[#-- Standard set of buckets for an account --]
[#if deploymentUnit?contains("s3")]

    [@cfOutput
        mode=accountListMode
        id=formatAccountDomainId()
        value=accountDomain
    /]
        
    [@cfOutput
        mode=accountListMode
        id=formatAccountDomainQualifierId()
        value=accountDomainQualifier
    /]

    [@cfOutput
        mode=accountListMode
        id=formatAccountDomainCertificateId()
        value=accountDomainCertificateId
    /]
    
    [#assign buckets = ["credentials", "code", "registry"]]
    [#list buckets as bucket]
    
        [#-- TODO: Should be using formatAccountS3Id() not formatS3Id() --]
        [#-- TODO: Remove outputId parameter below when TODO addressed --]
        
        [#assign existingName = getExistingReference(formatAccountS3Id(bucket))]
        [@createS3Bucket
            mode=accountListMode
            id=formatS3Id(bucket)
            name=
                existingName?has_content?then(
                    existingName,
                    formatName("account", bucket, accountObject.Seed))
            outputId=formatAccountS3Id(bucket)
        /]
    [/#list]
[/#if]


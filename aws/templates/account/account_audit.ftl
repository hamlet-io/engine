[#-- Auditing configuration --]
[#if deploymentUnit?contains("audit")] 

    [#if deploymentSubsetRequired("s3", true)]

        [#assign existingAuditName = getExistingReference(formatAccountS3Id("audit"))]
        [@createS3Bucket
            mode=listMode
            id=formatAccountS3Id("audit")
            name=valueIfContent(
                existingAuditName,
                existingAuditName,
                formatName("account", "audit", accountObject.Seed))
            cannedACL="LogDeliveryWrite"
        /]
    [/#if]
[/#if]
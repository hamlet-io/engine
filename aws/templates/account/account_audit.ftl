[#-- Auditing configuration --]
[#if deploymentUnit?contains("audit")] 

    [#if deploymentSubsetRequired("s3", true)]

        [#assign existingAuditName = getExistingReference(formatAccountS3Id("audit"))]

        [#assign lifecycleRules = [] ]
        [#assign sqsNotifications = []]
        [#assign dependencies = [] ]
        
        [@cfResource 
        mode=listMode
        id=formatAccountS3Id("audit")
        type="AWS::S3::Bucket"
        properties=
            {
                "BucketName" : valueIfContent(
                                    existingAuditName,
                                    existingAuditName,
                                    formatName("account", "audit", accountObject.Seed)),
                "AccessControl" : "LogDeliveryWrite"
            } +
            attributeIfContent(
                "LifecycleConfiguration",
                lifecycleRules,
                {
                    "Rules" : lifecycleRules
                }) +
            attributeIfContent(
                "NotificationConfiguration",
                sqsNotifications,
                {
                    "QueueConfigurations" : sqsNotifications
                }) 
        tags=getCfTemplateCoreTags("", tier, component)
        outputs=S3_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]

    [/#if]
[/#if]
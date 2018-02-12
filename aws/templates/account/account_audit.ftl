[#-- Auditing configuration --]
[#if deploymentUnit?contains("audit")]

    [#if accountObject.Seed?has_content]

        [#if deploymentSubsetRequired("audit", true)]
            [#assign lifecycleRules = []]
            [#assign sqsNotifications = []]
                
            [@cfResource 
                mode=listMode
                id=formatAccountS3Id("audit")
                type="AWS::S3::Bucket"
                properties=
                    {
                        "BucketName" : formatName("account", "audit", accountObject.Seed),
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
                tags=getCfTemplateCoreTags()
                outputs=S3_OUTPUT_MAPPINGS
            /]
        [/#if]
    [#else]
        [@cfPreconditionFailed listMode "account_audit" {} "No account seed provided" /]
    [/#if]
[/#if]

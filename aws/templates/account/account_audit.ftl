[#-- Auditing configuration --]
[#if deploymentUnit?contains("audit") || (allDeploymentUnits!false) ]

    [#if accountObject.Seed?has_content]

        [#if deploymentSubsetRequired("audit", true)]
            [#assign lifecycleRules = []]

            [#if accountObject.Audit.Expiration?has_content ]
                [#assign lifecycleRules += 
                    getS3LifecycleRule(
                        accountObject.Audit.Expiration, 
                        accountObject.Audit.Offline)
                ]
            [/#if]
        
            [#assign sqsNotifications = []]
            
            [@cfResource 
                mode=listMode
                id=formatAccountS3Id("audit")
                type="AWS::S3::Bucket"
                properties=
                    {
                        "BucketName" : formatName("account", "audit", accountObject.Seed),
                        "AccessControl" : "LogDeliveryWrite",
                        "VersioningConfiguration" : {
                            "Status" : "Enabled"
                        }
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

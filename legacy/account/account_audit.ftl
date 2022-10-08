[#-- Auditing configuration --]
[#if getCLODeploymentUnit()?contains("audit") || (groupDeploymentUnits!false) ]

    [#if accountObject.Seed?has_content]

        [#if deploymentSubsetRequired("generationcontract", false)]
            [@addDefaultGenerationContract subsets="template" /]
        [/#if]

        [#assign s3EncryptionEnabled = accountObject.S3.Encryption.Enabled  ]

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

            [@createS3Bucket
                id=formatAccountS3Id("audit")
                name=formatName("account", "audit", accountObject.Seed)
                encrypted=s3EncryptionEnabled
                encryptionSource="AES256"
                lifecycleRules=lifecycleRules
                versioning=true
                cannedACL="LogDeliveryWrite"
                publicAccessBlockConfiguration=(
                    getPublicAccessBlockConfiguration()
                )
            /]
        [/#if]
    [#else]
        [@precondition
            function="account_audit"
            detail="No account seed provided"
        /]
    [/#if]
[/#if]

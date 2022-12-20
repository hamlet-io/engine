[#-- Auditing configuration --]
[#if getCLODeploymentUnit()?contains("audit") || (groupDeploymentUnits!false) ]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_SIMPLE_STORAGE_SERVICE,
            AWS_CLOUDTRAIL_SERVICE
        ]
        deploymentFramework=getCLODeploymentFramework()
    /]

    [#if accountObject.Seed?has_content]

        [#if deploymentSubsetRequired("generationcontract", false)]
            [@addDefaultGenerationContract subsets="template" /]
        [/#if]

        [#assign s3EncryptionEnabled = accountObject.S3.Encryption.Enabled  ]

        [#if deploymentSubsetRequired("audit", true)]
            [#assign lifecycleRules = []]

            [#assign auditBucketId = formatAccountS3Id("audit")]

            [#if accountObject.Audit.Expiration?has_content ]
                [#assign lifecycleRules +=
                    getS3LifecycleRule(
                        accountObject.Audit.Expiration,
                        accountObject.Audit.Offline)
                ]
            [/#if]

            [#assign sqsNotifications = []]
            [#assign auditBucketPolicyStatements = []]

            [#if (accountObject.ProviderAuditing.StorageLocations)?values?filter( x -> x.Type == "Object")?size == 1 ]

                [#assign cloudTrailObjectStore = (accountObject.ProviderAuditing.StorageLocations)?values?filter(x -> x.Type == "Object")?first ]

                [#assign auditBucketPolicyStatements = combineEntities(
                    auditBucketPolicyStatements,
                    getS3BucketStatement(
                        [
                            "s3:GetBucketAcl"
                        ],
                        auditBucketId,
                        "",
                        "",
                        {
                            "Service": "cloudtrail.amazonaws.com"
                        },
                        {
                            "StringEquals" : {
                                "aws:SourceArn": formatRegionalArn(
                                    "cloudtrail",
                                    r'trail/' + getAccountCloudTrailProviderAuditingName()
                                )
                            }
                        }
                    ) +
                    getS3Statement(
                        [
                            "s3:PutObject"
                        ],
                        auditBucketId,
                        formatRelativePath(
                            getAccountCloudTrailProviderAuditingS3Prefix(),
                            "AWSLogs"
                        ),
                        "*",
                        {
                            "Service": "cloudtrail.amazonaws.com"
                        },
                        {
                            "StringEquals": {
                                "aws:SourceArn": formatRegionalArn(
                                    "cloudtrail",
                                    formatRelativePath(
                                        "trail",
                                        getAccountCloudTrailProviderAuditingName()
                                    )
                                ),
                                "s3:x-amz-acl": "bucket-owner-full-control"
                            }
                        }
                    ),
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#if]

            [#if auditBucketPolicyStatements?has_content ]
                [@createBucketPolicy
                    id=formatAccountResourceId(AWS_S3_BUCKET_POLICY_RESOURCE_TYPE, auditBucketId)
                    bucketId=auditBucketId
                    statements=auditBucketPolicyStatements
                /]
            [/#if]

            [@createS3Bucket
                id=auditBucketId
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

[#-- Auditing configuration --]
[#if getCLODeploymentUnit()?contains("audit") || (groupDeploymentUnits!false) ]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_SIMPLE_STORAGE_SERVICE,
            AWS_CLOUDTRAIL_SERVICE,
            AWS_IDENTITY_SERVICE
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
            [#assign auditReplicationRoleId = formatAccountResourceId(AWS_IAM_ROLE_RESOURCE_TYPE, "audit", "replication")]

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

            [#assign replicationRules = []]
            [#assign replicationPolicy = []]

            [#list accountObject.Audit.ReplicationRules?values?filter(x -> x.Enabled ) as replicationRule  ]

                [#assign replicationPolicy +=  s3ReplicaDestinationPermission( replicationRule.Destination.Id ) ]

                [#assign filterPrefix = ""]
                [#assign filterTags = {}]

                [#list replicationRule.Filters?values?filter(x -> x.Enabled ) as filter ]

                    [#switch filter.Type ]
                        [#case "Prefix"]

                            [#if ! filterPrefix?has_content]
                                [#assign filterPrefix = filter["Type:Prefix"]["Prefix"]]
                            [#else]
                                [@fatal
                                    message="Only a single prefix rule is permitted per replication rule"
                                    context={
                                        "Bucket": "Account Audit",
                                        "Rule": replicationRule
                                    }
                                /]
                            [/#if]
                            [#break]

                        [#case "Tag" ]
                            [#assign filterTags = mergeObjects(
                                    filterTags,
                                    { filter["Type:Tag"]["Key"] : filter["Type:Tag"]["Value" ] }
                                )
                            ]
                            [#break]
                    [/#switch]

                [/#list]

                [#assign replicationRules += [
                    getS3ReplicationRule(
                        replicationRule.Destination.Id,
                        true,
                        "",
                        false,
                        "",
                        (replicationRule.Destination.ProviderId != "__local__")?then(
                            replicationRule.Destination.ProviderId,
                            ""
                        ),
                        getS3ReplicationRuleFilter(
                            filterPrefix,
                            filterTags
                        ),
                        replicationRule.Priority
                    )
                ]]
            [/#list]

            [#if deploymentSubsetRequired("iam", true) &&
                    isPartOfCurrentDeploymentUnit(auditReplicationRoleId)]

                [#assign rolePolicies =
                        arrayIfContent(
                            getPolicyDocument(
                                s3ReplicaSourcePermission(auditBucketId) +
                                s3ReplicationConfigurationPermission(auditBucketId),
                                "replication"),
                            replicationRules
                        ) +
                        arrayIfContent(
                            getPolicyDocument(
                                replicationPolicy,
                                "replicationdestinations"
                            ),
                            replicationPolicy
                        )]

                [#if rolePolicies?has_content ]
                    [@createRole
                        id=auditReplicationRoleId
                        trustedServices=["s3.amazonaws.com"]
                        policies=rolePolicies
                    /]
                [/#if]
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
                replicationConfiguration=replicationRules?has_content?then(
                    getS3ReplicationConfiguration(
                        auditReplicationRoleId,
                        replicationRules
                    ),
                    {}
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

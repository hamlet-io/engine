[#-- AWS CloudTrail log forwarding --]
[#if getCLODeploymentUnit()?contains("cloudtrail") || (groupDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=["deploymentcontract", "template"] /]
    [/#if]

    [#if deploymentSubsetRequired("deploymentcontract", false)]
        [@addDefaultAWSDeploymentContract /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_IDENTITY_SERVICE,
            AWS_CLOUDWATCH_SERVICE,
            AWS_SIMPLE_STORAGE_SERVICE,
            AWS_CLOUDTRAIL_SERVICE,
            AWS_KEY_MANAGEMENT_SERVICE
        ]
        deploymentFramework=getCLODeploymentFramework()
    /]

    [#assign cloudTrailId = formatAccountResourceId(AWS_CLOUDTRAIL_TRAIL_RESOURCE_TYPE)]
    [#assign cloudTrailName = getAccountCloudTrailProviderAuditingName()]
    [#assign cloudTrailRoleId = formatAccountResourceId(AWS_IAM_ROLE_RESOURCE_TYPE, "cloudtrail")]
    [#assign cloudTrailCloudWatchLogGroupId = formatAccountResourceId(AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE, "cloudtrail" )]
    [#assign cloudTrailCloudWatchLogGroupName = formatAbsolutePath(
        "cloudtrail",
        accountObject.ProviderAuditing.Scope,
        (accountObject.ProviderAuditing.Scope == "Account")?then(
            accountObject.ProviderId,
            ((tenantObject.Name)!tenantObject.Id)
        )
    )]

    [#assign accountCMKId = formatAccountCMKTemplateId()]
    [#assign accountCMKArn = getExistingReference(accountCMKId, ARN_ATTRIBUTE_TYPE, getCLOSegmentRegion())]

    [#assign cloudtrailS3BucketId = formatAccountS3Id("audit")]
    [#assign cloudtrailS3KeyPrefix = ""]
    [#assign cloudtrailCloudWatchLogsRequired = false]

    [#list accountObject.ProviderAuditing.StorageLocations as id, storageLocation ]
        [#if storageLocation.Type == "Object" ]
            [#assign cloudtrailS3KeyPrefix = getAccountCloudTrailProviderAuditingS3Prefix()]
        [/#if]

        [#if storageLocation.Type == "Logs"]
            [#assign cloudtrailCloudWatchLogsRequired = true ]
        [/#if]
    [/#list]

    [#if deploymentSubsetRequired("iam", true)
            && isPartOfCurrentDeploymentUnit(cloudTrailRoleId)
            && cloudtrailCloudWatchLogsRequired ]

        [@createRole
            id=cloudTrailRoleId
            trustedServices=[
                "cloudtrail.amazonaws.com"
            ]
            policies=[
                getPolicyDocument(
                    cwLogsPolicy(
                        [
                            "logs:CreateLogStream",
                            "logs:PutLogEvents"
                        ],
                        cloudTrailCloudWatchLogGroupName
                    ),
                    "logging"
                )
            ]
        /]
    [/#if]

    [#if deploymentSubsetRequired("lg", true)
            && isPartOfCurrentDeploymentUnit(cloudTrailCloudWatchLogGroupId)
            && cloudtrailCloudWatchLogsRequired]

        [#if (accountObject.Logging.Encryption.Enabled)!false  ]
            [#if ! getExistingReference(accountCMKId)?has_content ]
                [@fatal
                    message="Account CMK not found"
                    detail="Run the cmk deployment at the account level to create the CMK"
                /]
            [/#if]
        [/#if]

        [@createLogGroup
            id=cloudTrailCloudWatchLogGroupId
            name=cloudTrailCloudWatchLogGroupName
            kmsKeyId=accountCMKArn
        /]
    [/#if]

    [#if deploymentSubsetRequired("cloudtrail", true)]

        [#if accountObject.ProviderAuditing.StorageLocations?values?filter( x -> x.Type == "Object")?size != 1 ]
            [@fatal
                message="S3 Cloud Trail must have a single Object store to put logs in"
                detail="Add a Object type storage location for Provider Auditing"
                context={
                    "Account": accountObject.Id,
                    "ProviderAuditing" : accountObject.ProviderAuditing
                }
            /]
        [/#if]

        [#if accountObject.ProviderAuditing.StorageLocations?values?filter( x -> x.Type == "Logs")?size > 1 ]
            [@fatal
                message="Only 1 CloudWatch Log group can be defined for Cloud Trail Logging"
                detail="Remove any extra Logs storage locations from your Provider Auditing"
                context={
                    "Account": accountObject.Id,
                    "ProviderAuditing" : accountObject.ProviderAuditing
                }
            /]
        [/#if]

        [@createCloudTrailTrail
            id=cloudTrailId
            name=cloudTrailName
            enabled=accountObject.ProviderAuditing.Enabled
            s3BucketId=cloudtrailS3BucketId
            s3KeyPrefix=cloudtrailS3KeyPrefix
            organizationTrail=(accountObject.ProviderAuditing.Scope == "Tenancy")?then(true, false)
            multiRegion=true
            logFileValidation=true
            includeGlobalServices=true
            insightSelectors=(accountObject.ProviderAuditing["aws:InsightReporting"])?then(
                getCloudTrailTrailInsightSelectors(
                    ["CallRate", "ErrorRate"]
                ),
                []
            )
            cloudWatchLogGroupId=cloudtrailCloudWatchLogsRequired?then(cloudTrailCloudWatchLogGroupId, "")
            cloudWatchLogsRoleId=cloudtrailCloudWatchLogsRequired?then(cloudTrailRoleId, "")
            kmsKeyId=(accountObject.ProviderAuditing.Encryption.Enabled)?then(
                formatAccountCMKTemplateId(),
                ""
            )
        /]
    [/#if]
[/#if]

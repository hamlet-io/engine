[#-- SMS --]
[#if getCLODeploymentUnit()?contains("sms") || (groupDeploymentUnits!false) ]


    [@includeProviderComponentDefinitionConfiguration
        provider=SHARED_PROVIDER
        component=MOBILENOTIFIER_COMPONENT_TYPE
    /]
    [@includeProviderComponentDefinitionConfiguration
        provider=AWS_PROVIDER
        component=MOBILENOTIFIER_COMPONENT_TYPE
    /]

    [@includeProviderComponentConfiguration
        provider=AWS_PROVIDER
        component=MOBILENOTIFIER_COMPONENT_TYPE
        services=[AWS_CLOUDWATCH_SERVICE, AWS_SIMPLE_NOTIFICATION_SERVICE]
    /]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_IDENTITY_SERVICE,
            AWS_KEY_MANAGEMENT_SERVICE
        ]
        deploymentFramework=getCLODeploymentFramework()
    /]

    [#assign cloudWatchRoleId = formatAccountRoleId("sms","cloudwatch")]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=["deplyoymentcontract", "epilogue", "cli"] /]
    [/#if]

    [#if deploymentSubsetRequired("deploymentcontract", false)]
        [@addDefaultAWSDeploymentContract epilogue=true stack=false /]
    [/#if]

    [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(cloudWatchRoleId)]
        [@createRole
            id=cloudWatchRoleId
            trustedServices=["sns.amazonaws.com"]
            policies=
                getPolicyDocument(
                    cwLogsProducePermission() +
                    cwLogsConfigurePermission(),
                    "sms"
                )
        /]
    [/#if]

    [#assign lgId = formatMobileNotifierLogGroupId(MOBILENOTIFIER_SMS_ENGINE, "", false) ]
    [#assign lgFailureId = formatMobileNotifierLogGroupId(MOBILENOTIFIER_SMS_ENGINE, "", true) ]
    [#assign accountCMKId = formatAccountCMKTemplateId()]

    [#assign accountCMKArn = getExistingReference(accountCMKId, ARN_ATTRIBUTE_TYPE, getCLOSegmentRegion())]

    [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(lgId) ]

        [#if (accountObject.Logging.Encryption.Enabled)!false ]
            [#if ! getExistingReference(accountCMKId)?has_content ]

                [#assign preconditionsMet = false]
                [@fatal
                    message="Account CMK not found"
                    detail="Run the cmk deployment at the account level to create the CMK"
                /]
            [/#if]
        [/#if]

        [@createLogGroup
            id=lgId
            name=formatMobileNotifierLogGroupName(MOBILENOTIFIER_SMS_ENGINE, "", false)
            kmsKeyId=accountCMKArn
        /]

        [@createLogGroup
            id=lgFailureId
            name=formatMobileNotifierLogGroupName(MOBILENOTIFIER_SMS_ENGINE, "", true)
            kmsKeyId=accountCMKArn
        /]
    [/#if]

    [#assign smsS3Id = formatAccountS3Id("ops") ]
    [#assign smsResourceId = "sms" ]
    [#assign smsCliCommand = "setsmsattributes" ]

    [#-- Need to run the unit twice or use an IAM unit so the role can be included in the CLI --]
    [#if deploymentSubsetRequired("cli", false) ]

        [#-- TODO(mfl): Remove use of internal function when accounts support refactored --]
        [#-- It is a hack for now                                                        --]
        [#assign smsSettings = internalCreateAccountSettings() ]
        [#assign successSamplingRate =
            contentIfContent(
                (smsSettings["SMS_SUCCESS_SAMPLING_RATE"].Value)!"",
                "100"
            ) ]
        [#assign smsType =
            contentIfContent(
                (smsSettings["SMS_DEFAULT_TYPE"].Value)!"",
                "Transactional"
            ) ]
        [@addCliToDefaultJsonOutput
            id=smsResourceId
            command=smsCliCommand
            content=
                {
                    "attributes": {
                        "DeliveryStatusSuccessSamplingRate" : successSamplingRate,
                        "DefaultSMSType" : smsType
                    } +
                    attributeIfContent(
                        "MonthlySpendLimit",
                        (smsSettings["SMS_MONTHLY_SPEND_LIMIT"].Value)!""
                    ) +
                    attributeIfContent(
                        "DefaultSenderID",
                        (smsSettings["SMS_SENDER_ID"].Value)!""
                    ) +
                    attributeIfContent(
                        "DeliveryStatusIAMRole",
                        getExistingReference(cloudWatchRoleId, ARN_ATTRIBUTE_TYPE)
                    ) +
                    attributeIfContent(
                        "UsageReportS3Bucket",
                        getExistingReference(smsS3Id)
                    )
                }
        /]
    [/#if]

    [#if deploymentSubsetRequired("epilogue", false) ]
        [@addToDefaultBashScriptOutput
            content=
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)",
                    "      # Get cli config file",
                    "      split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?",
                    "      # Apply SMS account settings",
                    "      info \"Applying SMS account settings ...\"",
                    "      #",
                    "      update_sms_account_attributes" +
                    "      \"" + getRegion() + "\" " +
                    "      \"$\{tmpdir}/cli-" +
                               smsResourceId + "-" + smsCliCommand + ".json\" || return $?"
                ] +
                [
                    "      ;;",
                    "esac"
                ]
        /]
    [/#if]
[/#if]

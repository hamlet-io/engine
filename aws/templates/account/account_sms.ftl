[#-- SMS --]
[#if deploymentUnit?contains("sms") || (allDeploymentUnits!false) ]
    [#assign cloudWatchRoleId = formatAccountRoleId("sms","cloudwatch")]
    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets=["epilogue", "cli"] /]
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
    [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(lgId) ]
        [@createLogGroup
            id=lgId
            name=formatMobileNotifierLogGroupName(MOBILENOTIFIER_SMS_ENGINE, "", false) /]

        [@createLogGroup
            id=lgFailureId
            name=formatMobileNotifierLogGroupName(MOBILENOTIFIER_SMS_ENGINE, "", true) /]
    [/#if]

    [#assign smsS3Id = formatAccountS3Id("ops") ]
    [#assign smsResourceId = "sms" ]
    [#assign smsCliCommand = "setsmsattributes" ]

    [#-- Need to run the unit twice or use an IAM unit so the role can be included in the CLI --]
    [#if deploymentSubsetRequired("cli", false) ]

        [#assign smsSettings = getAccountSettings() ]
        [#assign successSamplingRate =
            contentIfContent(
                getSetting(smsSettings, ["SMS", "SUCCESS", "SAMPLING", "RATE"], true).Value,
                "100"
            ) ]
        [#assign smsType =
            contentIfContent(
                getSetting(smsSettings, ["SMS", "DEFAULT", "TYPE"], true).Value,
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
                        getSetting(smsSettings, ["SMS", "MONTHLY", "SPEND", "LIMIT"], true).Value
                    ) +
                    attributeIfContent(
                        "DefaultSenderID",
                        getSetting(smsSettings, ["SMS", "SENDER", "ID"], true).Value
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
                    "      \"" + region + "\" " +
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


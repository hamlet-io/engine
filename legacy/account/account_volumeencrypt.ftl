[#-- Volume Encryption --]
[#if getDeploymentUnit()?contains("volumeencrypt") || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets="epilogue" /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_KEY_MANAGEMENT_SERVICE,
            AWS_ELASTIC_COMPUTE_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [#assign volumeEncryptResourceId = formatEC2AccountVolumeEncryptionId() ]
    [#assign volumeEncryptionEnabled = true ]

    [#assign kmsKeyArn = getExistingReference(formatAccountCMKTemplateId(), ARN_ATTRIBUTE_TYPE)]

    [#if deploymentSubsetRequired("epilogue", false) ]

        [#if ! kmsKeyArn?has_content ]
            [@fatal
                message="Account CMK not found"
                detail="Create account level CMK before enabling volume encryption"
            /]
        [/#if]

        [@addToDefaultBashScriptOutput
            content=
                [
                    r'case ${STACK_OPERATION} in',
                    r'  create|update)',
                    r'      info "Managing EBS Volume Encryption state..."',
                    r'      manage_ec2_volume_encryption' +
                    r'      "' + region + r'" ' +
                    r'      "true"' +
                    r'      "' + kmsKeyArn + r'"'
                ] +
                pseudoStackOutputScript(
                    "Volume Encryption",
                    {
                        volumeEncryptResourceId : volumeEncryptionEnabled?c
                    }
                ) +
                [
                    r'      ;;',
                    r' delete)',
                    r'      info "Managing EBS Volume Encryption state..."',
                    r'      manage_ec2_volume_encryption' +
                    r'      "' + region + r'" ' +
                    r'      "false"' +
                    r'      "alias/aws/ebs"'
                    r'      ;;',
                    r'esac'
                ]
        /]
    [/#if]
[/#if]

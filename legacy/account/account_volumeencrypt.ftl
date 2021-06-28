[#-- Volume Encryption --]
[#if getCLODeploymentUnit()?contains("volumeencrypt") || (groupDeploymentUnits!false) ]
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
    [#assign volumeEncryptionKmsKeyId = formatEc2AccountVolumeEncryptionKMSKeyId()]
    [#assign volumeEncryptKmsKeyArn = getExistingReference(volumeEncryptionKmsKeyId, ARN_ATTRIBUTE_TYPE)]

    [#assign volumeEncryptionEnabled = true ]

    [#if accountObject.Volume.Encryption.Enabled ]
        [#if deploymentSubsetRequired("epilogue", false) ]

            [#if ! volumeEncryptKmsKeyArn?has_content ]
                [@fatal
                    message="VolumeEncryption CMK not found"
                    detail="Run cmk deployment to create volume encryption cmk"
                /]
            [/#if]

            [@addToDefaultBashScriptOutput
                content=
                    [
                        r'case ${STACK_OPERATION} in',
                        r'  create|update)',
                        r'      info "Managing EBS Volume Encryption state..."',
                        r'      manage_ec2_volume_encryption' +
                        r'      "' + regionId + r'" ' +
                        r'      "true"' +
                        r'      "' + volumeEncryptKmsKeyArn + r'"'
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
                        r'      "' + regionId + r'" ' +
                        r'      "false"' +
                        r'      "alias/aws/ebs"'
                        r'      ;;',
                        r'esac'
                    ]
            /]
        [/#if]
    [/#if]
[/#if]

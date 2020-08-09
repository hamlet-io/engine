[#-- Account level CMK --]
[#if getDeploymentUnit()?contains("cmk") || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets="template" /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_KEY_MANAGEMENT_SERVICE,
            AWS_SYSTEMS_MANAGER_SERVICE,
            AWS_IDENTITY_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [#if (accountObject.Encryption.Alias.IncludeSeed)!false ]
        [#assign cmkKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk", accountObject.Seed)) ]
        [#assign consoleKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk", "console", accountObject.Seed)) ]
        [#assign volumeEncryptionKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk", "volume", "encrypt", accountObject.Seed)) ]
    [#else]
        [#assign cmkKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk")) ]
        [#assign consoleKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk", "console")) ]
        [#assign volumeEncryptionKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk", "volume", "encrypt" )) ]
    [/#if]

    [#assign cmkKeyId = formatAccountCMKTemplateId()]
    [#assign cmkKeyName = formatName("account", "cmk")]

    [#assign cmkKeyAliasId = formatDependentResourceId(AWS_CMK_ALIAS_RESOURCE_TYPE, cmkKeyId)]

    [#if deploymentSubsetRequired("cmk", true) ]

        [#if isPartOfCurrentDeploymentUnit(cmkKeyId)]

            [@createCMK
                id=cmkKeyId
                description=cmkKeyName
                statements=
                    [
                        getPolicyStatement(
                            "kms:*",
                            "*",
                            {
                                "AWS": formatAccountPrincipalArn()
                            }
                        )
                    ]
            /]

            [@createCMKAlias
                id=cmkKeyAliasId
                name=cmkKeyAliasName
                cmkId=cmkKeyId
            /]
        [/#if]

        [#if (accountObject.Volume.Encryption.Enabled)!false ]

            [#assign volumeEncryptionKmsKeyId = formatEc2AccountVolumeEncryptionKMSKeyId()]
            [#assign volumeEncryptionKmsKeyName = formatName("account", "cmk", "volume", "encrypt")]
            [#assign volumeEncryptionKmsKeyAliasId = formatDependentResourceId(AWS_CMK_ALIAS_RESOURCE_TYPE, volumeEncryptionKmsKeyId)]

            [#-- Check that service linked role exists --]
            [#assign autoScaleRoleDeployed = false ]
            [#list getReferenceData(SERVICEROLE_REFERENCE_TYPE) as id,ServiceRole ]
                [#if ServiceRole.ServiceName == "autoscaling.amazonaws.com" ]
                    [#assign autoScaleRoleDeployed = getExistingReference( formatAccountServiceLinkedRoleId(id) )?has_content ]
                [/#if]
            [/#list]

            [#if ! autoScaleRoleDeployed ]
                [@fatal
                    message="autoscaling.amazonaws.com service linked role not deployed"
                    detail="Check ServiceRoles reference data and run account level IAM deployment"
                /]
            [/#if]

            [#if isPartOfCurrentDeploymentUnit(volumeEncryptionKmsKeyId)]

                [@createCMK
                    id=volumeEncryptionKmsKeyId
                    description=volumeEncryptionKmsKeyName
                    statements=
                        [
                            getPolicyStatement(
                                "kms:*",
                                "*",
                                {
                                    "AWS": formatAccountPrincipalArn()
                                }
                            ),
                            getPolicyStatement(
                                [
                                    "kms:Encrypt",
                                    "kms:Decrypt",
                                    "kms:ReEncrypt*",
                                    "kms:GenerateDataKey*",
                                    "kms:DescribeKey"
                                ],
                                "*",
                                {
                                    "AWS": [
                                        formatGlobalArn(
                                            "iam",
                                            "role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
                                        )
                                    ]
                                },
                                {},
                                true,
                                "AutoScale Service Linked Role"
                            ),
                            getPolicyStatement(
                                [
                                    "kms:CreateGrant"
                                ],
                                "*",
                                {
                                    "AWS": [
                                        formatGlobalArn(
                                            "iam",
                                            "role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
                                        )
                                    ]
                                },
                                {
                                    "Bool": {
                                        "kms:GrantIsForAWSResource": true
                                    }
                                },
                                true,
                                "AutoScale Attachment of persistent resources"
                            )
                        ]
                /]

                [@createCMKAlias
                    id=volumeEncryptionKmsKeyAliasId
                    name=volumeEncryptionKeyAliasName
                    cmkId=volumeEncryptionKmsKeyId
                /]
            [/#if]
        [/#if]

        [#if (accountObject.Console.Encryption.DedicatedKey)!false ]

            [#assign consoleKeyId = formatAccountSSMSessionManagerKMSKeyId() ]
            [#assign consoleKeyName = formatName("account", "cmk", "console")]
            [#assign consoleKeyAliasId = formatDependentResourceId(AWS_CMK_ALIAS_RESOURCE_TYPE, consoleKeyId)]

            [#if isPartOfCurrentDeploymentUnit(consoleKeyId)]
                [@createCMK
                    id=consoleKeyId
                    description=consoleKeyName
                    statements=
                        [
                            getPolicyStatement(
                                "kms:*",
                                "*",
                                {
                                    "AWS": formatAccountPrincipalArn()
                                }
                            )
                        ]
                /]

                [@createCMKAlias
                    id=consoleKeyAliasId
                    name=consoleKeyAliasName
                    cmkId=consoleKeyId
                /]
            [/#if]
        [/#if]
    [/#if]
[/#if]

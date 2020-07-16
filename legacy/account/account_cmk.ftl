[#-- Account level CMK --]
[#if getDeploymentUnit()?contains("cmk") || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets="template" /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_KEY_MANAGEMENT_SERVICE,
            AWS_SYSTEMS_MANAGER_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [#if accountObject.Encryption.Alias.IncludeSeed!false ]
        [#assign cmkKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk", accountObject.Seed)) ]
        [#assign consoleKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk", "console", accountObject.Seed)) ]
    [#else]
        [#assign cmkKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk")) ]
        [#assign consoleKeyAliasName = formatRelativePath( "alias", formatName("account", "cmk", "console")) ]
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
                id=cmkKeyAliasId
                name=cmkKeyAliasName
                cmkId=cmkKeyId
            /]
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

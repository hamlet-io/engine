[#if getCLODeploymentUnit()?contains("console") || (groupDeploymentUnits!false) ]

    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract
            subsets=[ "prologue", "template" ]
            alternatives=[
                "primary",
                { "subset" : "template", "alternative" : "replace1" },
                { "subset" : "template", "alternative" : "replace2" }
            ]
        /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_SYSTEMS_MANAGER_SERVICE,
            AWS_KEY_MANAGEMENT_SERVICE,
            AWS_IDENTITY_SERVICE,
            AWS_CLOUDWATCH_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [#assign consoleSSMDocumentId = formatAccountSSMSessionManagerDocumentId() ]
    [#assign consoleSSMDocumentName = "SSM-SessionManagerRunShell"]

    [#assign consoleLgId = formatAccountSSMSessionManagerLogGroupId() ]
    [#assign consoleLgName = formatAccountSSMSessionManagerLogGroupName()]

    [#assign consoleLogBucketId = formatAccountSSMSessionManagerLogBucketId() ]
    [#assign consoleLogBucketName = formatAccountSSMSessionManagerLogBucketName() ]
    [#assign consoleLogBucketPrefix = formatAccountSSMSessionManagerLogBucketPrefix()]

    [#assign consoleLoggingDestinations = accountObject.Console.LoggingDestinations ]

    [#assign consoleDocumentDependencies = []]

    [#assign consoleCMKId = getAccountSSMSessionManagerKMSKeyId()]
    [#assign accountCMKArn = getExistingReference(accountCMKId, ARN_ATTRIBUTE_TYPE, getCLOSegmentRegion())]

    [#if deploymentSubsetRequired("console", true) &&
            ! getExistingReference(consoleCMKId)?has_content ]
        [@fatal
            message="Account CMK not found"
            detail="Run the cmk deployment at the account level to create the CMK"
        /]
    [/#if]

    [#assign SSMDocumentInput = {
        "kmsKeyId" : getExistingReference(consoleCMKId)
    }]

    [#list consoleLoggingDestinations as loggingDestination ]
        [#switch loggingDestination ]
            [#case "cloudwatch"]
                [#if deploymentSubsetRequired("lg", true) &&
                        isPartOfCurrentDeploymentUnit(consoleLgId)]

                    [#if (accountObject.Logging.Encryption.Enabled)!false  ]
                        [#if ! getExistingReference(accountCMKId)?has_content ]
                            [@fatal
                                message="Account CMK not found"
                                detail="Run the cmk deployment at the account level to create the CMK"
                            /]
                        [/#if]
                    [/#if]

                    [@createLogGroup
                        id=consoleLgId
                        name=consoleLgName
                        kmsKeyId=accountCMKArn
                    /]
                [/#if]

                [#assign SSMDocumentInput += {
                        "cloudWatchLogGroupName": consoleLgName,
                        "cloudWatchEncryptionEnabled" : false
                    }]
                [#break]

            [#case "s3"]
                [#assign consoleDocumentDependencies += [ consoleLogBucketId] ]
                [#if deploymentSubsetRequired("console", true) &&
                        isPartOfCurrentDeploymentUnit(consoleLogBucketId)]
                    [@createS3Bucket
                        id=consoleLogBucketId
                        name=consoleLogBucketName
                        encrypted=true
                        kmsKeyId=consoleCMKId
                        versioning=true
                    /]
                [/#if]

                [#assign SSMDocumentInput += {
                    "s3BucketName": getReference(consoleLogBucketId),
                    "s3KeyPrefix" : consoleLogBucketPrefix,
                    "s3EncryptionEnabled" : true
                }]
                [#break]
        [/#switch]
    [/#list]

    [#assign documentContent =
        {
            "schemaVersion": "1.0",
            "description": "Document to hold regional settings for Session Manager",
            "sessionType": "Standard_Stream",
            "inputs": SSMDocumentInput
        }]

    [#-- We need to make sure the document hasn't been created via the console or through a script --]
    [#if deploymentSubsetRequired("prologue", false)]
        [@addToDefaultBashScriptOutput
            content=
                [
                    r'info "Setting up for SSM Documents using CFN"'
                ] +
                ( ! (getExistingReference(consoleSSMDocumentId)?has_content ))?then(
                    [
                        r'case ${STACK_OPERATION} in',
                        r'  create|update)',
                        r'      info "Cleaning documents which might not have been created by CFN"',
                        r'      cleanup_ssm_document' +
                        r'      "' + getRegion() + r'" ' +
                        r'      "' + consoleSSMDocumentName + r'" ',
                        r'      ;;',
                        r'esac'
                    ],
                    []
                )
        /]
    [/#if]

    [#if deploymentSubsetRequired("console", true) &&
            ! ( getCLODeploymentUnitAlternative() == "replace1" ) ]

        [@createSSMDocument
            id=consoleSSMDocumentId
            name=consoleSSMDocumentName
            content=documentContent
            tags=getCfTemplateCoreTags("", "", "", "", false, false, 7)
            documentType="Session"
            dependencies=consoleDocumentDependencies
        /]
    [/#if]
[/#if]

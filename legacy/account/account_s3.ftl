[#-- Standard set of buckets for an account --]
[#if getDeploymentUnit()?contains("s3") || (groupDeploymentUnits!false) ]
    [#if accountObject.Seed?has_content]
        [#if deploymentSubsetRequired("generationcontract", false)]
            [@addDefaultGenerationContract subsets=["template", "epilogue"] /]
        [/#if]

        [@includeServicesConfiguration
            provider=AWS_PROVIDER
            services=[
                AWS_KEY_MANAGEMENT_SERVICE
            ]
            deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
        /]

        [#assign accountCMKId = formatAccountCMKTemplateId()]
        [#assign s3EncryptionEnabled = (accountObject.S3.Encryption.Enabled)!false ]
        [#assign s3EncryptionSource = (accountObject.S3.Encryption.EncryptionSource)!"EncryptionService" ]
        [#assign s3VersioningEnabled = (accountObject.S3.Versioning.Enabled)!false]

        [#if s3EncryptionEnabled ]
            [#-- TODO replace dodgy reference to AWS for legacy freemarker --]
            [#if deploymentSubsetRequired("s3", true) &&
                    ! getExistingReference(AWS_PROVIDER, accountCMKId)?has_content ]
                [@fatal
                    message="Account CMK not found"
                    detail="Run the cmk deployment at the account level to create the CMK"
                /]
            [/#if]
        [/#if]

        [#if deploymentSubsetRequired("s3", true)]

            [#assign buckets = ["credentials", "code", "registry"] ]
            [#list buckets as bucket]

                [#-- TODO: Should be using formatAccountS3Id() not formatS3Id() --]
                [#-- TODO: Remove outputId parameter below when TODO addressed --]

                [#-- TODO replace dodgy reference to AWS for legacy freemarker --]
                [#assign existingName = getExistingReference(AWS_PROVIDER, formatAccountS3Id(bucket))]
                [#assign bucketName = valueIfContent(
                                            existingName,
                                            existingName,
                                            formatName("account", bucket, accountObject.Seed))]
                [#assign bucketId = formatS3Id(bucket) ]
                [#assign bucketPolicyId = formatResourceId(AWS_S3_BUCKET_POLICY_RESOURCE_TYPE, bucket ) ]

                [@createS3Bucket
                    id=bucketId
                    name=bucketName
                    versioning=s3VersioningEnabled
                    encrypted=s3EncryptionEnabled
                    encryptionSource=s3EncryptionSource
                    kmsKeyId=accountCMKId
                    outputId=formatAccountS3Id(bucket)
                /]

                [#if bucket == "registry" ]
                    [#assign awsShareAccounts = (accountObject.Registry.ShareAccess.AWSAccounts)![] ]
                    [#assign policyStatements = [] ]
                    [#list awsShareAccounts as awsAccount ]

                        [#assign accountPrincipal = {
                            "AWS" : formatGlobalArn(
                                            "iam",
                                            "root",
                                            awsAccount)
                        }]

                        [#assign policyStatements +=
                                s3ReadPermission(
                                    bucketName,
                                    "",
                                    "*",
                                    accountPrincipal
                                ) + s3ListPermission(
                                    bucketName,
                                    "",
                                    "*",
                                    accountPrincipal
                                )]
                    [/#list]

                    [#if policyStatements?has_content ]
                        [@createBucketPolicy
                            id=bucketPolicyId
                            bucket=bucketName
                            statements=policyStatements
                            dependencies=bucketId
                        /]
                    [/#if]
                [/#if]
            [/#list]
        [/#if]
        [#if deploymentSubsetRequired("epilogue", false)]
            [#-- TODO replace dodgy reference to AWS for legacy freemarker --]
            [#assign existingName = getExistingReference(AWS_PROVIDER, formatAccountS3Id("code"))]
            [#assign codeBucket = valueIfContent(
                        existingName,
                        existingName,
                        formatName("account", "code", accountObject.Seed))]
            [#assign existingName = getExistingReference(AWS_PROVIDER, formatAccountS3Id("registry"))]
            [#assign registryBucket = valueIfContent(
                        existingName,
                        existingName,
                        formatName("account", "registry", accountObject.Seed))]

            [#assign scriptSyncContent = [] ]
            [#list scriptStores as key,scriptStore ]
                [#if scriptStore?is_hash]
                    [#assign storePrefix = scriptStore.Destination.Prefix!key ]
                    [#assign scriptSyncContent += [
                        "info \"Synching ScriptStore: " + key + "...\""
                    ]]

                    [#switch scriptStore.Engine ]
                        [#case "local" ]
                            [#assign scriptsDir = scriptStore.Source.Directory?replace("\\\{","{")]
                            [#assign scriptSyncContent += [
                                "if [[ -d \"" + scriptsDir + "\" ]]; then",
                                "       aws --region \"$\{ACCOUNT_REGION}\" s3 sync --delete --exclude=\".git*\" \"" + scriptsDir + "\" \"s3://" +
                                        codeBucket + "/" + storePrefix + "/\" ||",
                                "       { exit_status=$?; fatal \"Can't sync to the code bucket\"; return \"$\{exit_status}\"; }",
                                "else",
                                    "fatal \"Local Script store not found - no sync performed\"; return 1",
                                "fi"
                            ]]
                            [#break]

                        [#case "github" ]
                            [#assign scriptSyncContent += [
                                "stage_dir=\"$\{tmpdir}/" + storePrefix + "\"",
                                "mkdir -p \"$\{stage_dir}\"",
                                "# Clone the Repo",
                                "clone_git_repo \"github\" \"github.com\" \"" + scriptStore.Source.Repository +"\" \"" + scriptStore.Source.Branch + "\" \"$\{stage_dir}\" ||",
                                "{ exit_status=$?; fatal \"Can't clone the script store\"; return \"$\{exit_status}\"; }",
                                "       aws --region \"$\{ACCOUNT_REGION}\" s3 sync --delete --exclude=\".git*\" \"$\{stage_dir}\" \"s3://" +
                                        codeBucket + "/" + storePrefix + "/\" ||",
                                "       { exit_status=$?; fatal \"Can't sync to the code bucket\"; return \"$\{exit_status}\"; }"
                            ]]
                            [#break]
                    [/#switch]
                [/#if]
            [/#list]

            [#-- Make sure code bucket is up to date and registires initialised --]
            [@addToDefaultBashScriptOutput
                content=
                    [
                        "function sync_code_bucket() {"
                    ] +
                        scriptSyncContent +
                    [
                        "}",
                        "#",
                        "function initialise_registries() {",
                        "  info \"Initialising the registry bucket ...\"",
                        "  local registry_marker=\"$(getTopTempDir)/registry\"",
                        "  touch \"$\{registry_marker}\"",
                        "  for registry in \"$@\"; do",
                        "    aws --region \"$\{ACCOUNT_REGION}\" s3 cp \"$\{registry_marker}\" \"s3://" +
                               registryBucket + "/$\{registry}/.registry\" ||",
                        "      { exit_status=$?; fatal \"Can't initialise the $\{registry} registry\"; return \"$\{exit_status}\"; }",
                        "  done",
                        "  return 0",
                        "}",
                        "#",
                        "case $\{STACK_OPERATION} in",
                        "  create|update)",
                        "    sync_code_bucket || return $?",
                        "    initialise_registries \"dataset\" \"contentnode\" \"lambda\" \"pipeline\" \"scripts\" \"spa\" \"swagger\" \"openapi\" \"rdssnapshot\" || return $?",
                        "    ;;",
                        " esac"
                    ]
            /]
        [/#if]
    [#else]
        [@precondition
            function="account_s3"
            detail="No account seed provided"
        /]
    [/#if]
[/#if]

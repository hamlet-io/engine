
[#macro setupAccountS3Buckets deploymentSubset versioning encryption encryptionSource kmsKeyId replica replicaRegions shareAccountIds=[] ]

    [#local buckets = ["credentials", "code", "registry"] ]
    [#list buckets as bucket]

        [#if replica ]
            [#local bucketName = formatAccountS3ReplicaBucketName(bucket, getCLOSegmentRegion())]
        [#else]
            [#local bucketName = formatAccountS3PrimaryBucketName(bucket)]
        [/#if]

        [#local bucketId = formatS3Id(bucket) ]
        [#local bucketPolicyId = formatResourceId(AWS_S3_BUCKET_POLICY_RESOURCE_TYPE, bucket ) ]

        [#local replicationConfiguration = {}]

        [#if ( ! replica) ]
            [#if replicaRegions?has_content ]

                [#local replicationRoleId = formatAccountRoleId("s3replication", bucket) ]

                [#local replicaionPolicies = s3ReplicaSourcePermission(bucketId) +
                                s3ReplicationConfigurationPermission(bucketId) ]

                [#if encryption ]
                   [#local replicaionPolicies +=  s3EncryptionReadPermission(kmsKeyId, bucketName, "*", regionId)]
                [/#if]

                [#local rolePolicies =
                        [
                            getPolicyDocument(
                                replicaionPolicies,
                                "replication"
                            )
                        ]
                    ]


                [#local replicaDestinationPolicies = []]

                [@debug message="kmsKeyId" context=kmsKeyId enabled=true /]

                [#local replicationRules = [] ]
                [#list replicaRegions as replicaRegion ]

                    [#local destinationBucketName = formatAccountS3ReplicaBucketName(bucket, replicaRegion) ]
                    [#local replicaDestinationPolicies += s3ReplicaDestinationPermission(destinationBucketName) ]

                    [#if getExistingReference(kmsKeyId, ARN_ATTRIBUTE_TYPE, replicaRegion)?has_content ]
                        [#local replicaDestinationPolicies += s3EncryptionAllPermission(
                                                                                kmsKeyId,
                                                                                destinationBucketName,
                                                                                "*",
                                                                                replicaRegion)]
                    [/#if]

                    [#local replicationRules +=
                        [
                            getS3ReplicationRule(
                                formatGlobalArn("s3", destinationBucketName, ""),
                                true
                                "",
                                getExistingReference(kmsKeyId, ARN_ATTRIBUTE_TYPE, replicaRegion)?has_content,
                                getExistingReference(kmsKeyId, ARN_ATTRIBUTE_TYPE, replicaRegion),
                                ""
                            )
                        ]
                    ]
                [/#list]

                [#local rolePolicies +=
                            [
                                getPolicyDocument(
                                replicaDestinationPolicies,
                                "replicadestinations"
                                )
                            ]
                        ]

                [#local replicationConfiguration = getS3ReplicationConfiguration(
                                                        replicationRoleId,
                                                        replicationRules
                                                    )]


                [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(replicationRoleId)]
                    [#if rolePolicies?has_content ]
                        [@createRole
                            id=replicationRoleId
                            trustedServices=["s3.amazonaws.com"]
                            policies=rolePolicies
                        /]
                    [/#if]
                [/#if]
            [/#if]
        [/#if]

        [#if deploymentSubsetRequired(deploymentSubset, true)]
            [@createS3Bucket
                id=bucketId
                name=bucketName
                versioning=versioning
                encrypted=encryption
                encryptionSource=encryptionSource
                kmsKeyId=accountCMKArn
                outputId=formatAccountS3Id(bucket)
                replicationConfiguration=replicationConfiguration
            /]

            [#if bucket == "registry" ]
                [#assign awsShareAccounts = shareAccountIds ]
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
        [/#if]
    [/#list]
[/#macro]


[#assign preconditionsMet = true]

[#if getCLODeploymentUnit() == "s3" || getCLODeploymentUnit() == "s3replica" || (groupDeploymentUnits!false) ]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_SIMPLE_STORAGE_SERVICE,
            AWS_KEY_MANAGEMENT_SERVICE,
            AWS_IDENTITY_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [#assign accountCMKId = formatAccountCMKTemplateId()]
    [#assign accountCMKArn = getExistingReference(accountCMKId, ARN_ATTRIBUTE_TYPE, getCLOSegmentRegion())]
    [#assign s3EncryptionEnabled = (accountObject.S3.Encryption.Enabled)!false ]
    [#assign s3EncryptionSource = (accountObject.S3.Encryption.EncryptionSource)!"EncryptionService" ]
    [#assign s3VersioningEnabled = (accountObject.S3.Versioning.Enabled)!false]

    [#if s3EncryptionEnabled ]
        [#if deploymentSubsetRequired("s3", true) &&
                ! getExistingReference(accountCMKId)?has_content ]

            [#assign preconditionsMet = false]
            [@fatal
                message="Account CMK not found"
                detail="Run the cmk deployment at the account level to create the CMK"
            /]
        [/#if]
    [/#if]

    [#if !(accountObject.Seed?has_content)]
        [#assign preconditionsMet = false]
        [@precondition
            function="account_s3"
            detail="No account seed provided"
        /]
    [/#if]
[/#if]

[#-- Standard set of buckets for an account --]
[#if preconditionsMet && ( getCLODeploymentUnit() == "s3" || (groupDeploymentUnits!false) ) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=["template", "epilogue"] /]
    [/#if]

    [@setupAccountS3Buckets
        deploymentSubset="s3"
        versioning=s3VersioningEnabled
        encryption=s3EncryptionEnabled
        encryptionSource=s3EncryptionSource
        kmsKeyId=accountCMKId
        replica=false
        replicaRegions=accountObject.Registry.ReplicaRegions
        shareAccountIds=(accountObject.Registry.ShareAccess.AWSAccounts)![]
    /]

    [#if deploymentSubsetRequired("epilogue", false)]
        [#assign existingName = getExistingReference(formatAccountS3Id("code"))]
        [#assign codeBucket = valueIfContent(
                    existingName,
                    existingName,
                    formatName("account", "code", accountObject.Seed))]
        [#assign existingName = getExistingReference(formatAccountS3Id("registry"))]
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
                            r'stage_dir="${tmpdir}/' + storePrefix + r'"',
                            r'mkdir -p "${stage_dir}"',
                            r'# Clone the Repo',
                            r'git_url="$( format_git_url "github" "github.com" "' + scriptStore.Source.Repository + r'" )"',
                            r'clone_git_repo "${git_url}" "' + scriptStore.Source.Branch + r'" "${stage_dir}" || { exit_status=$?; fatal "Cant clone the script store"; return "${exit_status}"; }',
                            r'       aws --region "${ACCOUNT_REGION}" s3 sync --delete --exclude=".git*" "${stage_dir}" "s3://' + codeBucket + r'/' + storePrefix + r'/" ||',
                            r'       { exit_status=$?; fatal "Cant sync to the code bucket"; return "${exit_status}"; }'
                        ]]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]
        [#assign scriptSyncContent += [
            r'# Ensure there is some content for the function',
            r'return 0'
        ]]

        [#-- Make sure code bucket is up to date and registries initialised --]
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
[/#if]


[#if preconditionsMet && ( getCLODeploymentUnit() == "s3replica" || (groupDeploymentUnits!false)) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=["template"] /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_KEY_MANAGEMENT_SERVICE,
            AWS_IDENTITY_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [@setupAccountS3Buckets
        deploymentSubset="s3"
        versioning=s3VersioningEnabled
        encryption=s3EncryptionEnabled
        encryptionSource=s3EncryptionSource
        kmsKeyId=accountCMKArn
        replica=true
        replicaRegions=(accountObject.Registry.ReplicaRegions)![]
        shareAccountIds=(accountObject.Registry.ShareAccess.AWSAccounts)![]
    /]

[/#if]

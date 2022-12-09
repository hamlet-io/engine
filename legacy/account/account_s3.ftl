
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
                   [#local replicaionPolicies +=  s3EncryptionReadPermission(kmsKeyId, bucketName, "*", getRegion())]
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
                publicAccessBlockConfiguration=(
                    getPublicAccessBlockConfiguration()
                )
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
                        bucketId=bucketId
                        statements=policyStatements
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
        shareAccountIds=(accountObject.Registry.ShareAccess.ProviderIds)![]
    /]

    [#if deploymentSubsetRequired("epilogue", false)]
        [#assign currentCodeBucket =
            contentIfContent(
                getCodeBucket(),
                formatName("account", "code", accountObject.Seed)
            ) ]
        [#assign currentRegistryBucket =
            contentIfContent(
                getRegistryBucket(),
                formatName("account", "registry", accountObject.Seed)
            ) ]

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
                                    currentCodeBucket + "/" + storePrefix + "/\" ||",
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
                            r'       aws --region "${ACCOUNT_REGION}" s3 sync --delete --exclude=".git*" "${stage_dir}" "s3://' + currentCodeBucket + r'/' + storePrefix + r'/" ||',
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
        [#if deploymentSubsetRequired("epilogue", false) ]
            [@addToDefaultBashScriptOutput
                content=
                    [
                        "function sync_code_bucket() {"
                    ] +
                        scriptSyncContent +
                    [
                        "}",
                        "sync_code_bucket || exit $?"
                    ]
            /]
        [/#if]
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
        shareAccountIds=(accountObject.Registry.ShareAccess.ProviderIds)![]
    /]

[/#if]

[#-- Baseline Component --]
[#if componentType == BASELINE_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#-- make sure we only have one occurence --]
        [#if  ! ( core.Tier.Id == "mgmt" &&
                core.Component.Id == "baseline" && 
                core.Version.Id == "" && 
                core.Instance.Id == "" ) ]

            [@cfException
                mode=listMode
                description="The baseline component can only be deployed once as an unversioned component"
                context=core
            /]
            [#break ]
        [/#if]
            
        [#-- Segment Seed --]
        [#assign segmentSeedId = resources["segmentSeed"].Id ]
        [#if !(getExistingReference(segmentSeedId)?has_content) ]
            
            [#assign segmentSeedValue = resources["segmentSeed"].Value]

            [#if deploymentSubsetRequired("prologue", false)]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "case $\{STACK_OPERATION} in",
                        "  create|update)"
                    ] +
                    pseudoStackOutputScript(
                            "Seed Values",
                            { segmentSeedId : segmentSeedValue },
                            "seed"
                    ) +
                    [            
                        "       ;;",
                        "       esac"
                    ]
                /]
            [/#if]
        [/#if]

        [#-- Monitoring Topic --]
        [#if (resources["segmentSNSTopic"]!{})?has_content ]
            [#assign topicId = resources["segmentSNSTopic"].Id ]
            [#if deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true)]
                [@createSegmentSNSTopic
                    mode=listMode
                    id=topicId
                /]
            [/#if]
        [/#if]

        [#-- Subcomponents --]
        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign subCore = subOccurrence.Core ]
            [#assign subSolution = subOccurrence.Configuration.Solution ]
            [#assign subResources = subOccurrence.State.Resources ]

            [#-- Storage bucket --]
            [#if subCore.Type == BASELINE_DATA_COMPONENT_TYPE ]
                [#assign bucketId = subResources["bucket"].Id ]
                [#assign bucketName = subResources["bucket"].Name ]
                [#assign bucketPolicyId = subResources["bucketpolicy"].Id ]
                [#assign legacyS3 = subResources["bucket"].LegacyS3 ]

                [#if ( deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true) && legacyS3 == false ) || 
                    ( deploymentSubsetRequired("s3") && legacyS3 == true) ]

                    [#assign lifecycleRules = [] ]
                    [#list subSolution.Lifecycles?values as lifecycle ]
                        [#assign lifecycleRules += 
                            getS3LifecycleRule(lifecycle.Expiration, lifecycle.Offline, lifecycle.Prefix)]
                    [/#list]

                    [#assign sqsNotifications = [] ]
                    [#assign sqsNotificationIds = [] ]
                    [#assign bucketDependencies = [] ]

                    [#list subSolution.Notifications!{} as id,notification ]
                        [#if notification?is_hash]
                            [#list notification.Links?values as link]
                                [#if link?is_hash]
                                    [#assign linkTarget = getLinkTarget(subOccurrence, link, false) ]
                                    [@cfDebug listMode linkTarget false /]
                                    [#if !linkTarget?has_content]
                                        [#continue]
                                    [/#if]

                                    [#assign linkTargetResources = linkTarget.State.Resources ]

                                    [#switch linkTarget.Core.Type]
                                        [#case AWS_SQS_RESOURCE_TYPE ]
                                            [#if isLinkTargetActive(linkTarget) ]
                                                [#assign sqsId = linkTargetResources["queue"].Id ]
                                                [#assign sqsNotificationIds = [ sqsId ]]
                                                [#list notification.Events as event ]
                                                    [#assign sqsNotifications +=
                                                            getS3SQSNotification(sqsId, event, notification.Prefix, notification.Suffix) ]
                                                [/#list]
                                                
                                            [/#if]
                                            [#break]
                                    [/#switch]
                                [/#if]
                            [/#list]
                        [/#if]
                    [/#list]

                    [#list sqsNotificationIds as sqsId ]
                        [#assign sqsPolicyId =
                            formatS3NotificationsQueuePolicyId(
                                bucketId,
                                sqsId) ]
                        [@createSQSPolicy
                                mode=listMode
                                id=sqsPolicyId
                                queues=sqsId
                                statements=sqsS3WritePermission(sqsId, bucketName)
                            /]
                        [#assign bucketDependencies += [sqsPolicyId] ]
                    [/#list]

                    [@createS3Bucket
                        mode=listMode
                        id=bucketId
                        name=bucketName
                        versioning=subSolution.Versioning
                        lifecycleRules=lifecycleRules
                        sqsNotifications=sqsNotifications
                        dependencies=bucketDependencies
                    /]
                                
                    [#-- role based bucket policies --]
                    [#assign bucketPolicy = []]
                    [#switch subSolution.Role ]
                        [#case "operations" ]
                            [#assign cfAccess =
                                getExistingReference(formatDependentCFAccessId(bucketId), CANONICAL_ID_ATTRIBUTE_TYPE)]
                            
                            [#assign bucketPolicy += 
                                s3WritePermission(
                                    bucketName,
                                    "AWSLogs",
                                    "*",
                                    {
                                        "AWS": "arn:aws:iam::" + regionObject.Accounts["ELB"] + ":root"
                                    }
                                ) +
                                s3ReadBucketACLPermission(
                                    bucketName,
                                    { "Service": "logs." + regionId + ".amazonaws.com" }
                                ) +
                                s3WritePermission(
                                    bucketName,
                                    "",
                                    "*",
                                    { "Service": "logs." + regionId + ".amazonaws.com" },
                                    { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } }
                                ) +
                                valueIfContent(
                                    s3ReadPermission(
                                        bucketName,
                                        formatSegmentPrefixPath("settings"),
                                        "*",
                                        {
                                            "CanonicalUser": cfAccess
                                        }
                                    )
                                    cfAccess,
                                    []
                                )]
                            [#break]
                        [#case "appdata" ] 
                            [#if dataPublicEnabled ]
    
                                [#assign dataPublicWhitelistCondition =
                                    getIPCondition(getGroupCIDRs(dataPublicIPAddressGroups, true)) ]

                                [#assign bucketPolicy += s3ReadPermission(
                                            bucketName,
                                            formatSegmentPrefixPath("apppublic"),
                                            "*",
                                            "*",
                                            dataPublicWhitelistCondition
                                        )]
                            [/#if]
                            [#break]
                    [/#switch]
    
                    [#if bucketPolicy?has_content ]
                        [@createBucketPolicy
                            mode=listMode
                            id=bucketPolicyId
                            bucket=bucketName
                            statements=bucketPolicy
                            dependencies=bucketId
                        /]
                    [/#if]
                [/#if]            
            [/#if]

            [#-- Access Keys --]
            [#if subCore.Type == BASELINE_KEY_COMPONENT_TYPE ]
                

                [#switch subSolution.Engine ]
                    [#case "cmk" ]

                        [#assign legacyCmk = subResources["cmk"].LegacyKey]
                        [#assign cmkId = subResources["cmk"].Id ]
                        [#assign cmkResourceId = subResources["cmk"].Id]
                        [#assign cmkName = subResources["cmk"].Name ]
                        [#assign cmkAliasId = subResources["cmkAlias"].Id]
                        [#assign cmkAliasName = subResources["cmkAlias"].Name]


                        [#if ( deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true) && legacyCmk == false ) || 
                            ( deploymentSubsetRequired("cmk") && legacyCmk == true) ]

                            [@createCMK
                                mode=listMode
                                id=cmkResourceId
                                description=cmkName
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
                                outputId=cmkId
                            /]

                            [@createCMKAlias
                                mode=listMode
                                id=cmkAliasId
                                name=cmkAliasName
                                cmkId=cmkId
                            /]
                        [/#if]
                    [#break]

                    [#case "ssh" ]

                        [#assign localKeyPairId = subResources["localKeyPair"].Id]
                        [#assign localKeyPairPublicKey = subResources["localKeyPair"].PublicKey ]
                        [#assign localKeyPairPrivateKey = subResources["localKeyPair"].PrivateKey ]

                        [#assign ec2KeyPairId = subResources["ec2KeyPair"].Id ]
                        [#assign ec2KeyPairName = subResources["ec2KeyPair"].Name ]

                        [#if deploymentSubsetRequired("epilogue", false)]
                            [#if sshPerEnvironment]
                                [#-- Make sure SSH credentials are in place --]
                                [@cfScript
                                    mode=listMode
                                    content=
                                    [
                                        "function manage_ssh_credentials() {"
                                        "  info \"Checking SSH credentials ...\"",
                                        "  #",
                                        "  # Create SSH credential for the segment",
                                        "  mkdir -p \"$\{SEGMENT_OPERATIONS_DIR}\"",
                                        "  create_pki_credentials \"$\{SEGMENT_OPERATIONS_DIR}\" " +
                                                "\"" + regionId + "\" " +
                                                "\"" + accountObject.Id + "\" " + 
                                                "\"" + localKeyPairPublicKey + "\" " +
                                                "\"" + localKeyPairPrivateKey + "\" || return $?",
                                        "  #",
                                        "  # Update the credential if required",
                                        "  if ! check_ssh_credentials" + " " +
                                            "\"" + regionId + "\" " +
                                            "\"$\{key_pair_name}\"; then",
                                        "    pem_file=\"$\{SEGMENT_OPERATIONS_DIR}/" + localKeyPairPublicKey + "\"",
                                        "    update_ssh_credentials" + " " +
                                            "\"" + regionId + "\" " +
                                            "\"$\{key_pair_name}\" " +
                                            "\"$\{pem_file}\" || return $?",
                                        "    [[ -f \"$\{SEGMENT_OPERATIONS_DIR}/" + localKeyPairPrivateKey + ".plaintext\" ]] && ",
                                        "      { encrypt_file" + " " +
                                                "\"" + regionId + "\"" + " " +
                                                "segment" + " " +
                                                "\"$\{SEGMENT_OPERATIONS_DIR}/" + localKeyPairPrivateKey + ".plaintext\"" + " " +
                                                "\"$\{SEGMENT_OPERATIONS_DIR}/" + localKeyPairPrivateKey + "\" || return $?; }",
                                        "  fi",
                                        "  #"
                                    ] +
                                    pseudoStackOutputScript("SSH Key Pair", { formatId(ec2KeyPairId, "name") : "$\{key_pair_name}"}, "keypair") +
                                    [
                                        "  #",
                                        "  show_ssh_credentials" + " " +
                                            "\"" + regionId + "\" " +
                                            "\"$\{key_pair_name}\"",
                                        "  #",
                                        "  return 0"
                                        "}",
                                        "#",
                                        "# Determine the required key pair name",
                                        "key_pair_name=\"" + ec2KeyPairName + "\"",
                                        "#",
                                        "case $\{STACK_OPERATION} in",
                                        "  delete)",
                                        "    delete_ssh_credentials " + " " +
                                            "\"" + regionId + "\" " +
                                            "\"$\{key_pair_name}\" || return $?",
                                        "    delete_pki_credentials \"$\{SEGMENT_OPERATIONS_DIR}\" || return $?",
                                        "    rm -f \"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-keypair-pseudo-stack.json\"",
                                        "    ;;",
                                        "  create|update)",
                                        "    manage_ssh_credentials || return $?",
                                        "    ;;",
                                        " esac"
                                    ]
                                /]
                            [/#if]
                        [/#if]
                    [#break]

                    [#case "oai" ]
                        [#assign legacyKey = subResources["originAccessId"].LegacyKey ]
                        [#assign OAIId = subResources["originAccessId"].Id ]
                        [#assign OAIName = subResources["originAccessId"].Name ]

                        [#if legacyKey ]
                            [#if deploymentSubsetRequired("epilogue", false)]
                                [@cfScript
                                    mode=listMode
                                    content=
                                        [
                                            "function manage_oai_credentials() {"
                                            "  info \"Checking OAI credentials ...\"",
                                            "  #",
                                            "  local oai_file=\"$(getTopTempDir)/oai.json\"",
                                            "  update_oai_credentials" + " " +
                                                "\"" + regionId + "\" " +
                                                "\"" + OAIName + "\" " +
                                                "\"$\{oai_file}\" || return $?",
                                            "  #",
                                            "  oai_id=$(jq -r \".Id\" < \"$\{oai_file}\") || return $?",
                                            "  oai_canonical_id=$(jq -r \".S3CanonicalUserId\" < \"$\{oai_file}\") || return $?"
                                        ] +
                                        pseudoStackOutputScript(
                                            "Cloudfront Origin Access Identity",
                                            {
                                                OAIId : "$\{oai_id}",
                                                formatId(OAIId, "canonicalid") : "$\{oai_canonical_id}"
                                            }
                                        ) +
                                        [
                                            "}",
                                            "#",
                                            "case $\{STACK_OPERATION} in",
                                            "  delete)",
                                            "  delete_oai_credentials" + " " +
                                                "\"" + regionId + "\" " +
                                                "\"" + formatSegmentFullName() + "\" || return $?",
                                            "  rm -f \"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\"",
                                            "    ;;",
                                            "  create|update)",
                                            "    manage_oai_credentials || return $?",
                                            "    ;;",
                                            " esac"
                                        ]
                                /]
                            [/#if]
                        [#else]
                            [#if deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true)]
                                [@createCFOriginAccessIdentity 
                                    mode=listMode
                                    id=OAIId 
                                    name=OAIName
                                /]
                            [/#if]
                        [/#if]
                    [#break]
                [/#switch]
            [/#if]
        [/#list]
    [/#list]
[/#if]

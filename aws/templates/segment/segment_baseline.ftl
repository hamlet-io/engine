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
                    [#assign cfAccessCanonicalIds = [] ]

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
                                        [#case SQS_COMPONENT_TYPE ]
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

                    [#list subSolution.Links?values as link]
                        [#if link?is_hash]
                            [#assign linkTarget = getLinkTarget(occurrence, link, false) ]

                            [@cfDebug listMode linkTarget false /]

                            [#if !linkTarget?has_content]
                                [#continue]
                            [/#if]

                            [#assign linkTargetCore = linkTarget.Core ]
                            [#assign linkTargetConfiguration = linkTarget.Configuration ]
                            [#assign linkTargetResources = linkTarget.State.Resources ]
                            [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                            [#switch linkTargetCore.Type]

                                [#case BASELINE_KEY_COMPONENT_TYPE]
                                    [#if linkTargetConfiguration.Solution.Engine == "oai" ]
                                        [#assign cfAccessCanonicalIds += [ getReference( (linkTargetResources["originAccessId"].Id), CANONICAL_ID_ATTRIBUTE_TYPE )] ]
                                    [/#if]
                                    [#break]
                            [/#switch]
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

                            [#assign legacyOAIId = formatDependentCFAccessId(bucketId)]
                            [#if getExistingReference(legacyOAIId, CANONICAL_ID_ATTRIBUTE_TYPE)?has_content ]
                                [#assign cfAccessCanonicalIds += [ getExistingReference(legacyOAIId, CANONICAL_ID_ATTRIBUTE_TYPE) ]]
                            [/#if]

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
                                            "CanonicalUser": cfAccessCanonicalIds
                                        }
                                    )
                                    cfAccessCanonicalIds,
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
                        [#assign legacyKey = subResources["ec2KeyPair"].LegacyKey ]

                        [#if deploymentSubsetRequired("epilogue", false)]
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
                                valueIfTrue(
                                    [
                                        "   info \"Removing old ssh pseduo stack output\"",
                                        "   legacy_pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE/\"-baseline-\"/\"-cmk-\"}\")-keypair-pseudo-stack.json\"",
                                        "   if [ -f \"$\{legacy_pseudo_stack_file}\" ]; then",
                                        "       rm -f \"$\{legacy_pseudo_stack_file}\"",
                                        "   fi"
                                    ],
                                    legacyKey
                                ) + 
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
                    [#break]

                    [#case "oai" ]

                        [#assign OAIId = subResources["originAccessId"].Id ]
                        [#assign OAIName = subResources["originAccessId"].Name ]
                        [#assign legacyKey = false]

                        [#if subCore.SubComponent.Id == "oai" ]

                            [#-- legacy OAI lookup --]
                            [#assign opsDataLink = {
                                        "Tier" : "mgmt",
                                        "Component" : "baseline",
                                        "Instance" : "",
                                        "Version" : "",
                                        "DataBucket" : "opsdata"
                                }]

                            [#assign opsDataLinkTarget = getLinkTarget({}, opsDataLink )]

                            [#if opsDataLinkTarget?has_content ]
                                [#assign opsDataBucketId = opsDataLinkTarget.State.Resources["bucket"].Id ]
                                [#assign legacyOAIId = formatDependentCFAccessId(opsDataBucketId)]

                                [#if (getExistingReference(legacyOAIId!"", CANONICAL_ID_ATTRIBUTE_TYPE))?has_content ]
                                    [#assign legacyKey = true]
                                    [#assign OAIId = legacyOAIId ]
                                    [#assign OAIName = formatSegmentFullName()]
                                [/#if]
                            [/#if]
                        [/#if]

                        [#if legacyKey ]
                            [#if deploymentSubsetRequired("epilogue", false) ]
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
                                        valueIfTrue(
                                            [
                                                "   info \"Removing old oai pseduo stack output\"",
                                                "   legacy_pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE/\"-baseline-\"/\"-cmk-\"}\")-pseudo-stack.json\"",
                                                "   if [ -f \"$\{legacy_pseudo_stack_file}\" ]; then",
                                                "       rm -f \"$\{legacy_pseudo_stack_file}\"",
                                                "   fi"
                                            ],
                                            legacyKey
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

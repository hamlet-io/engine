[#ftl]
[#macro aws_baseline_cf_generationcontract_segment occurrence ]
    [@addDefaultGenerationContract subsets=["prologue", "template", "epilogue"] /]
[/#macro]

[#macro aws_baseline_cf_setup_segment occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#-- make sure we only have one occurence --]
    [#if  ! ( core.Tier.Id == "mgmt" &&
            core.Component.Id == "baseline" &&
            core.Version.Id == "" &&
            core.Instance.Id == "" ) ]

        [@fatal
            message="The baseline component can only be deployed once as an unversioned component"
            context=core
        /]
        [#return ]
    [/#if]

    [#-- Segment Seed --]
    [#local segmentSeedId = resources["segmentSeed"].Id ]
    [#if !(getExistingReference(segmentSeedId)?has_content) ]

        [#local segmentSeedValue = resources["segmentSeed"].Value]

        [#if deploymentSubsetRequired("prologue", false)]
            [@addToDefaultBashScriptOutput
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

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "Encryption" ], false, false )]

    [#local cmkResources = baselineLinks["Encryption"].State.Resources ]
    [#local cmkAlias = cmkResources["cmkAlias"].Name ]

    [@debug message={ "KeyAlias" : cmkAlias } enabled=true /]

    [#-- Subcomponents --]
    [#list occurrence.Occurrences![] as subOccurrence]

        [#local subCore = subOccurrence.Core ]
        [#local subSolution = subOccurrence.Configuration.Solution ]
        [#local subResources = subOccurrence.State.Resources ]

        [#-- Storage bucket --]
        [#if subCore.Type == BASELINE_DATA_COMPONENT_TYPE ]
            [#local bucketId = subResources["bucket"].Id ]
            [#local bucketName = subResources["bucket"].Name ]
            [#local bucketPolicyId = subResources["bucketpolicy"].Id ]
            [#local legacyS3 = subResources["bucket"].LegacyS3 ]

            [#if ( deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true) && legacyS3 == false ) ||
                ( deploymentSubsetRequired("s3") && legacyS3 == true) ]

                [#local lifecycleRules = [] ]
                [#list subSolution.Lifecycles?values as lifecycle ]
                    [#local lifecycleRules +=
                        getS3LifecycleRule(lifecycle.Expiration, lifecycle.Offline, lifecycle.Prefix)]
                [/#list]

                [#local notifications = [] ]
                [#local bucketDependencies = [] ]
                [#local cfAccessCanonicalIds = [] ]

                [#-- Backwards compatible support for legacy OAI keys --]
                [#local legacyOAIId = formatDependentCFAccessId(bucketId)]
                [#local legacyOAI =  getExistingReference(legacyOAIId, CANONICAL_ID_ATTRIBUTE_TYPE) ]

                [#if legacyOAI?has_content]
                    [#local cfAccessCanonicalIds += [ legacyOAI ]]
                [/#if]

                [#list subSolution.Notifications as id,notification ]
                    [#if notification?is_hash]
                        [#list notification.Links?values as link]
                            [#if link?is_hash]
                                [#local linkTarget = getLinkTarget(subOccurrence, link, false) ]
                                [@debug message="Link Target" context=linkTarget enabled=false /]
                                [#if !linkTarget?has_content]
                                    [#continue]
                                [/#if]

                                [#local linkTargetResources = linkTarget.State.Resources ]

                                [#if isLinkTargetActive(linkTarget) ]

                                    [#local resourceId = "" ]
                                    [#local resourceType = ""]

                                    [#switch linkTarget.Core.Type]
                                        [#case SQS_COMPONENT_TYPE ]
                                            [#local resourceId = linkTargetResources["queue"].Id ]
                                            [#local resourceType = linkTargetResources["queue"].Type ]

                                            [#local policyId =
                                                formatS3NotificationPolicyId(
                                                    bucketId,
                                                    resourceId) ]

                                            [#local bucketDependencies += [policyId] ]

                                            [#if deploymentSubsetRequired("s3", true)]
                                                [@createSQSPolicy
                                                    id=policyId
                                                    queues=resourceId
                                                    statements=sqsS3WritePermission(resourceId, bucketName)
                                                /]
                                            [/#if]

                                            [#break]

                                        [#case LAMBDA_FUNCTION_COMPONENT_TYPE ]
                                            [#local resourceId = linkTargetResources["lambda"].Id ]
                                            [#local resourceType = linkTargetResources["lambda"].Type ]

                                            [#local policyId =
                                                formatS3NotificationPolicyId(
                                                    bucketId,
                                                    resourceId) ]

                                            [#local bucketDependencies += [policyId] ]

                                            [#if deploymentSubsetRequired("s3", true)]
                                                [@createLambdaPermission
                                                    id=policyId
                                                    targetId=resourceId
                                                    sourceId=bucketId
                                                    sourcePrincipal="s3.amazonaws.com"
                                                /]
                                            [/#if]

                                            [#break]

                                        [#case TOPIC_COMPONENT_TYPE]
                                            [#local resourceId = linkTargetResources["topic"].Id ]
                                            [#local resourceType = linkTargetResources["topic"].Type ]
                                            [#local policyId =
                                                formatS3NotificationPolicyId(
                                                    bucketId,
                                                    resourceId) ]

                                            [#local bucketDependencies += [ policyId ]]

                                            [#if deploymentSubsetRequired("s3", true )]
                                                [@createSNSPolicy
                                                    id=policyId
                                                    topics=resourceId
                                                    statements=snsS3WritePermission(resourceId, bucketName)
                                                /]
                                            [/#if]
                                    [/#switch]

                                    [#list notification.Events as event ]
                                        [#local notifications +=
                                                getS3Notification(resourceId, resourceType, event, notification.Prefix, notification.Suffix) ]
                                    [/#list]
                                [/#if]
                            [/#if]
                        [/#list]
                    [/#if]
                [/#list]

                [#list subSolution.Links?values as link]
                    [#if link?is_hash]
                        [#local linkTarget = getLinkTarget(occurrence, link, false) ]

                        [@debug message="Link Target" context=linkTarget enabled=false /]

                        [#if !linkTarget?has_content]
                            [#continue]
                        [/#if]

                        [#local linkTargetCore = linkTarget.Core ]
                        [#local linkTargetConfiguration = linkTarget.Configuration ]
                        [#local linkTargetResources = linkTarget.State.Resources ]
                        [#local linkTargetAttributes = linkTarget.State.Attributes ]

                        [#switch linkTargetCore.Type]

                            [#case BASELINE_KEY_COMPONENT_TYPE]
                                [#if linkTargetConfiguration.Solution.Engine == "oai" ]
                                    [#local cfAccessCanonicalIds += [ getReference( (linkTargetResources["originAccessId"].Id), CANONICAL_ID_ATTRIBUTE_TYPE )] ]
                                [/#if]
                                [#break]
                        [/#switch]
                    [/#if]
                [/#list]

                [@createS3Bucket
                    id=bucketId
                    name=bucketName
                    versioning=subSolution.Versioning
                    lifecycleRules=lifecycleRules
                    notifications=notifications
                    dependencies=bucketDependencies
                /]

                [#-- role based bucket policies --]
                [#local bucketPolicy = []]
                [#switch subSolution.Role ]
                    [#case "operations" ]

                        [#local bucketPolicy +=
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

                            [#local dataPublicWhitelistCondition =
                                getIPCondition(getGroupCIDRs(dataPublicIPAddressGroups, true)) ]

                            [#local bucketPolicy += s3ReadPermission(
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

                    [#local legacyCmk = subResources["cmk"].LegacyKey]
                    [#local cmkId = subResources["cmk"].Id ]
                    [#local cmkResourceId = subResources["cmk"].ResourceId]
                    [#local cmkName = subResources["cmk"].Name ]
                    [#local cmkAliasId = subResources["cmkAlias"].Id]
                    [#local cmkAliasName = subResources["cmkAlias"].Name]


                    [#if ( deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true) && legacyCmk == false ) ||
                        ( deploymentSubsetRequired("cmk") && legacyCmk == true) ]

                        [@createCMK
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
                            id=cmkAliasId
                            name=cmkAliasName
                            cmkId=cmkResourceId
                        /]
                    [/#if]
                [#break]

                [#case "ssh" ]

                    [#local localKeyPairId = subResources["localKeyPair"].Id]
                    [#local localKeyPairPublicKey = subResources["localKeyPair"].PublicKey ]
                    [#local localKeyPairPrivateKey = subResources["localKeyPair"].PrivateKey ]

                    [#local ec2KeyPairId = subResources["ec2KeyPair"].Id ]
                    [#local ec2KeyPairName = subResources["ec2KeyPair"].Name ]
                    [#local legacyKey = subResources["ec2KeyPair"].LegacyKey ]

                    [#if deploymentSubsetRequired("epilogue", false)]
                        [#-- Make sure SSH credentials are in place --]
                        [@addToDefaultBashScriptOutput
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
                                "      { encrypt_kms_file" + " " +
                                        "\"" + regionId + "\" " +
                                        "\"$\{SEGMENT_OPERATIONS_DIR}/" + localKeyPairPrivateKey + ".plaintext\" " +
                                        "\"$\{SEGMENT_OPERATIONS_DIR}/" + localKeyPairPrivateKey + "\" " +
                                        "\"" + cmkAlias + "\" || return $?; }"
                                "  fi",
                                "  #"
                            ] +
                            pseudoStackOutputScript(
                                "SSH Key Pair",
                                {
                                    ec2KeyPairId : "$\{key_pair_name}",
                                    formatId(ec2KeyPairId, "name") : "$\{key_pair_name}"
                                },
                                "keypair"
                            ) +
                            valueIfTrue(
                                [
                                    "   info \"Removing old ssh pseudo stack output ...\"",
                                    "   legacy_pseudo_stack_file=\"$(fileBase \"$\{BASH_SOURCE}\")\"",
                                    "   legacy_pseudo_stack_filepath=\"$\{CF_DIR/baseline/cmk}/$\{legacy_pseudo_stack_file/-baseline-/-cmk-}-keypair-pseudo-stack.json\"",
                                    "   if [ -f \"$\{legacy_pseudo_stack_filepath}\" ]; then",
                                    "       info \"Deleting $\{legacy_pseudo_stack_filepath} ...\"",
                                    "       rm -f \"$\{legacy_pseudo_stack_filepath}\"",
                                    "   else",
                                    "       warn \"Unable to locate pseudo stack file $\{legacy_pseudo_stack_filepath}\"",
                                    "   fi"
                                ],
                                legacyKey,
                                []
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

                    [#local OAIId = subResources["originAccessId"].Id ]
                    [#local OAIName = subResources["originAccessId"].Name ]
                    [#local legacyKey = false]

                    [#if subCore.SubComponent.Id == "oai" ]

                        [#-- legacy OAI lookup --]
                        [#local opsDataLink = {
                                    "Id" : "opsData",
                                    "Name" : "opsData",
                                    "Tier" : "mgmt",
                                    "Component" : "baseline",
                                    "Instance" : "",
                                    "Version" : "",
                                    "DataBucket" : "opsdata"
                            }]

                        [#local opsDataLinkTarget = getLinkTarget(occurrence, opsDataLink )]

                        [#if opsDataLinkTarget?has_content ]
                            [#local opsDataBucketId = opsDataLinkTarget.State.Resources["bucket"].Id ]
                            [#local legacyOAIId = formatDependentCFAccessId(opsDataBucketId)]
                            [#local legacyOAIName = formatSegmentFullName()]

                            [#if (getExistingReference(legacyOAIId, CANONICAL_ID_ATTRIBUTE_TYPE))?has_content ]
                                [#local legacyKey = true]
                            [/#if]
                        [/#if]
                    [/#if]

                    [#if deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true)]
                        [@createCFOriginAccessIdentity
                            id=OAIId
                            name=OAIName
                        /]
                    [/#if]

                    [#if legacyKey ]
                        [#if deploymentSubsetRequired("epilogue", false) ]
                            [@addToDefaultBashScriptOutput
                                content=
                                    [
                                        "case $\{STACK_OPERATION} in",
                                        "  delete)",
                                        "    delete_oai_credentials" + " " +
                                               "\"" + regionId + "\" " +
                                               "\"" + legacyOAIName + "\" || return $?",
                                        "    rm -f \"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\"",
                                        "    ;;",
                                        "  create|update)",
                                        "    info \"Removing legacy oai credential ...\"",
                                        "    used=$(is_oai_credential_used" + " " +
                                               "\"" + regionId + "\" " +
                                               "\"" + legacyOAIName + "\" ) || return $?",
                                        "    if [[ \"$\{used}\" == \"true\" ]]; then",
                                        "      warn \"Legacy OAI in use - rerun the baseline unit to remove it once it is no longer in use ...\"",
                                        "    else",
                                        "      delete_oai_credentials" + " " +
                                                 "\"" + regionId + "\" " +
                                                 "\"" + legacyOAIName + "\" || return $?",
                                        "      info \"Removing legacy oai pseudo stack output\"",
                                        "      legacy_pseudo_stack_file=\"$(fileBase \"$\{BASH_SOURCE}\")\"",
                                        "      legacy_pseudo_stack_filepath=\"$\{CF_DIR/baseline/cmk}/$\{legacy_pseudo_stack_file/-baseline-/-cmk-}-pseudo-stack.json\"",
                                        "      if [ -f \"$\{legacy_pseudo_stack_filepath}\" ]; then",
                                        "         info \"Deleting $\{legacy_pseudo_stack_filepath} ...\"",
                                        "         rm -f \"$\{legacy_pseudo_stack_filepath}\"",
                                        "      else",
                                        "         warn \"Unable to locate pseudo stack file $\{legacy_pseudo_stack_filepath}\"",
                                        "      fi",
                                        "    fi",
                                        "    ;;",
                                        " esac"
                                    ]
                            /]
                        [/#if]
                    [/#if]
                [#break]
            [/#switch]
        [/#if]
    [/#list]
[/#macro]

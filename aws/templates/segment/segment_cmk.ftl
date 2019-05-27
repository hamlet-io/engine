[#-- KMS --]
[#--
[#if (componentType == "cmk") ]
    [#if deploymentSubsetRequired("cmk", true)]
        [#assign cmkId = formatSegmentCMKTemplateId()]
        [#assign cmkAliasId = formatSegmentCMKAliasId(cmkId)]

        [@createCMK
            mode=listMode
            id=cmkId
            description=formatSegmentFullName()
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
            outputId=formatSegmentCMKId()
        /]

        [@createCMKAlias
            mode=listMode
            id=cmkAliasId
            name=formatName("alias/" + formatSegmentFullName())
            cmkId=cmkId
        /]
    [/#if]
    [#if deploymentSubsetRequired("epilogue", false)]

        [#if sshPerEnvironment]
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
                                "\"" + accountObject.Id + "\" || return $?",
                        "  #",
                        "  # Update the credential if required",
                        "  if ! check_ssh_credentials" + " " +
                            "\"" + regionId + "\" " +
                             "\"$\{key_pair_name}\"; then",
                        "    pem_file=\"$\{SEGMENT_OPERATIONS_DIR}/.aws-" + accountObject.Id + "-" + regionId + "-ssh-crt.pem\"",
                        "    update_ssh_credentials" + " " +
                               "\"" + regionId + "\" " +
                               "\"$\{key_pair_name}\" " +
                               "\"$\{pem_file}\" || return $?",
                        "    [[ -f \"$\{SEGMENT_OPERATIONS_DIR}/.aws-" + accountObject.Id + "-" + regionId + "-ssh-prv.pem.plaintext\" ]] && ",
                        "      { encrypt_file" + " " +
                                 "\"" + regionId + "\"" + " " +
                                 "segment" + " " +
                                 "\"$\{SEGMENT_OPERATIONS_DIR}/.aws-" + accountObject.Id + "-" + regionId + "-ssh-prv.pem.plaintext\"" + " " +
                                 "\"$\{SEGMENT_OPERATIONS_DIR}/.aws-" + accountObject.Id + "-" + regionId + "-ssh-prv.pem\" || return $?; }",
                        "  fi",
                        "  #"
                      ] +
                      pseudoStackOutputScript("SSH Key Pair", {"keypairXsegmentXname" : "$\{key_pair_name}"}, "keypair") +
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
                        "key_pair_name=\"" + formatSegmentFullName() + "\"",
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
        [#assign bucketId = formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, "opsdata" ) ]
        [#if !getExistingReference(bucketId)?has_content ]
            [#assign bucketId = formatS3OperationsId() ]
        [/#if]
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
                        "\"" + formatSegmentFullName() + "\" " +
                        "\"$\{oai_file}\" || return $?",
                    "  #",
                    "  oai_id=$(jq -r \".Id\" < \"$\{oai_file}\") || return $?",
                    "  oai_canonical_id=$(jq -r \".S3CanonicalUserId\" < \"$\{oai_file}\") || return $?"
                ] +
                pseudoStackOutputScript(
                    "Cloudfront Origin Access Identity",
                    {
                        formatDependentCFAccessId(bucketId) : "$\{oai_id}",
                        formatDependentCFAccessId(bucketId, "canonicalid") : "$\{oai_canonical_id}"
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

[/#if]
--]


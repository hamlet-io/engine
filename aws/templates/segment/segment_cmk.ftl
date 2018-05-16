[#-- KMS --]
[#if (componentType == "cmk") ]
    [#if deploymentSubsetRequired("cmk", true)]
        [#-- TODO: Get rid of inconsistent id usage --]
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
                        "  create_pki_credentials \"$\{SEGMENT_OPERATIONS_DIR}\" || return $?",
                        "  #",
                        "  # Update the credential if required",
                        "  if ! check_ssh_credentials" + " " +
                            "\"" + regionId + "\" " +
                             "\"$\{key_pair_name}\"; then",
                        "    pem_file=\"$\{SEGMENT_OPERATIONS_DIR}/.aws-ssh-crt.pem\"",
                        "    update_ssh_credentials" + " " +
                               "\"" + regionId + "\" " +
                               "\"$\{key_pair_name}\" " +
                               "\"$\{pem_file}\" || return $?",
                        "    [[ -f \"$\{SEGMENT_OPERATIONS_DIR}/.aws-ssh-prv.pem.plaintext\" ]] && ",
                        "      { encrypt_file" + " " +
                                 "\"" + regionId + "\"" + " " +
                                 "segment" + " " +
                                 "\"$\{SEGMENT_OPERATIONS_DIR}/.aws-ssh-prv.pem.plaintext\"" + " " +
                                 "\"$\{SEGMENT_OPERATIONS_DIR}/.aws-ssh-prv.pem\" || return $?; }",
                        "  fi",
                        "  #",
                        "  create_pseudo_stack" + " " +
                             "\"SSH Key Pair\"" + " " +
                             "\"$\{key_pair_pseudo_stack_file}\"" + " " +
                             "\"keypairXsegmentXname\" \"$\{key_pair_name}\" || return $?",
                        "  #",
                        "  show_ssh_credentials" + " " +
                             "\"" + regionId + "\" " +
                             "\"$\{key_pair_name}\"",
                        "  #",
                        "  return 0"
                        "}",
                        "#",
                        "key_pair_pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-keypair-pseudo-stack.json\" ",
                        "#",
                        "# Determine the required key pair name",
                        "# Legacy support for existing keypairs for default segments",
                        "key_pair_name=\"" + formatName(productName, environmentName, segmentName) + "\"",
                        valueIfTrue(
                          "  check_ssh_credentials" + " " +
                               "\"" + regionId + "\" " +
                               "\"" + formatEnvironmentFullName() + "\" && key_pair_name=\"" + formatEnvironmentFullName() + "\"",
                          segmentName == "default",
                          "#"),
                        "#",
                        "case $\{STACK_OPERATION} in",
                        "  delete)",
                        "    delete_ssh_credentials " + " " +
                            "\"" + regionId + "\" " +
                            "\"$\{key_pair_name}\" || return $?",
                        "    delete_pki_credentials \"$\{SEGMENT_OPERATIONS_DIR}\" || return $?",
                        "    ;;",
                        "  create|update)",
                        "    manage_ssh_credentials || return $?",
                        "    ;;",
                        " esac"
                    ]
            /]
        [/#if]
        [#-- Origin Access Identity for any S3 based cloudfront distributions --]
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
                    "  oai_canonical_id=$(jq -r \".S3CanonicalUserId\" < \"$\{oai_file}\") || return $?",
                    "  create_pseudo_stack" + " " +
                         "\"Cloudfront Origin Access Identity\"" + " " +
                         "\"$\{oai_pseudo_stack_file}\"" + " " +
                         "\"cfaccessXs3XsegmentXops\" \"$\{oai_id}\"" + " " +
                         "\"cfaccessXs3XsegmentXopsXcanonicalid\" \"$\{oai_canonical_id}\" || return $?"
                    "}"
                    "#",
                    "oai_pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\" ",
                    "case $\{STACK_OPERATION} in",
                    "  delete)",
                    "  delete_oai_credentials" + " " +
                        "\"" + regionId + "\" " +
                        "\"" + formatSegmentFullName() + "\" || return $?",
                    "  rm -f \"$\{pseudo_stack_file}\"",
                    "    ;;",
                    "  create|update)",
                    "    manage_oai_credentials || return $?",
                    "    ;;",
                    " esac"
                ]
        /]
    [/#if]

[/#if]


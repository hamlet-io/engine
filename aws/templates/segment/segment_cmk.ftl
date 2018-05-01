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
                        "  mkdir -p \"$\{ENVIRONMENT_CREDENTIALS_DIR}\"",
                        "  create_pki_credentials \"$\{ENVIRONMENT_CREDENTIALS_DIR}\" || return $?",
                        "  #",
                        "  # Update the credential",
                        "  update_ssh_credentials" + " " +
                            "\"" + regionId + "\" " +
                            "\"" + formatEnvironmentFullName() + "\" " +
                            "\"$\{ENVIRONMENT_CREDENTIALS_DIR}/aws-ssh-crt.pem\" || return $?",
                        "  [[ -f \"$\{ENVIRONMENT_CREDENTIALS_DIR}/aws-ssh-prv.pem.plaintext\" ]] && ",
                        "    { encrypt_file" + " " +
                               "\"" + regionId + "\"" + " " +
                               "segment" + " " +
                               "\"$\{ENVIRONMENT_CREDENTIALS_DIR}/aws-ssh-prv.pem.plaintext\"" + " " +
                               "\"$\{ENVIRONMENT_CREDENTIALS_DIR}/aws-ssh-prv.pem\" || return $?; }",
                        "  return 0"
                        "}",
                        "#",
                        "case $\{STACK_OPERATION} in",
                        "  delete)",
                        "    delete_ssh_credentials " + " " +
                            "\"" + regionId + "\" " +
                            "\"" + formatEnvironmentFullName() + "\" || return $?",
                        "    delete_pki_credentials \"$\{ENVIRONMENT_CREDENTIALS_DIR}\" || return $?",
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
                         "\"$\{pseudo_stack_file}\"" + " " +
                         "\"cfaccessXs3XsegmentXops\" \"$\{oai_id}\"" + " " +
                         "\"cfaccessXs3XsegmentXopsXcanonicalid\" \"$\{oai_canonical_id}\" || return $?"
                    "}"
                    "#",
                    "pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\" ",
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


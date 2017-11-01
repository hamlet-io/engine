[#-- KMS --]
[#if (componentType == "cmk") ]
    [#if deploymentSubsetRequired("cmk", true)]
        [#-- TODO: Get rid of inconsistent id usage --]
        [#assign cmkId = formatSegmentCMKTemplateId()]
        [#assign cmkAliasId = formatSegmentCMKAliasId(cmkId)]
    
        [@createCMK
            mode=segmentListMode
            id=cmkId
            description=formatName(productName,segmentName)
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
            mode=segmentListMode
            id=cmkAliasId
            name=formatName("alias/" + productName, segmentName)
            cmkId=cmkId
        /]
    [/#if]
    [#if deploymentSubsetRequired("epilogue", false)]
        [#if sshPerSegment]
            [#-- Make sure SSH credentials are in place --]
            [@cfScript
                mode=applicationListMode
                content=
                    [
                        "function manage_ssh_credentials() {"
                        "  info \"Checking SSH credentials ...\"",
                        "  #",
                        "  # Create SSH credential for the segment",
                        "  mkdir -p \"$\{SEGMENT_CREDENTIALS_DIR}\"",
                        "  create_pki_credentials \"$\{SEGMENT_CREDENTIALS_DIR}\" || return $?",
                        "  #",
                        "  # Update the credential",
                        "  update_ssh_credentials" + " " +
                            "\"" + regionId + "\" " +
                            "\"" + productName + "-" + segmentName + "\" " +
                            "\"$\{SEGMENT_CREDENTIALS_DIR}/aws-ssh-crt.pem\" || return $?",
                        "  [[ -f \"$\{SEGMENT_CREDENTIALS_DIR}/aws-ssh-prv.pem.plaintext\" ]] && ",
                        "    { encrypt_file" + " " +
                               "\"" + regionId + "\"" + " " +
                               "segment" + " " +
                               "\"$\{SEGMENT_CREDENTIALS_DIR}/aws-ssh-prv.pem.plaintext\"" + " " +
                               "\"$\{SEGMENT_CREDENTIALS_DIR}/aws-ssh-prv.pem\" || return $?; }",
                        "  return 0"
                        "}",
                        "#",
                        "case $\{STACK_OPERATION} in",
                        "  delete)",
                        "    delete_ssh_credentials " + " " +
                            "\"" + regionId + "\" " +
                            "\"" + productName + "-" + segmentName + "\" || return $?",
                        "    delete_pki_credentials \"$\{SEGMENT_CREDENTIALS_DIR}\" || return $?",
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
            mode=applicationListMode
            content=
                [
                    "function manage_oai_credentials() {"
                    "  info \"Checking OAI credentials ...\"",
                    "  #",
                    "  local oai_file=\"./temp_oai.json\"",
                    "  update_oai_credentials" + " " +
                        "\"" + regionId + "\" " +
                        "\"" + productName + "-" + segmentName + "\" " +
                        "\"$\{oai_file}\" || return $?",
                    "  #",
                    "  oai_id=$(jq -r \".Id\" < \"$\{oai_file}\") || return $?",
                    "  oai_canonical_id=$(jq -r \".S3CanonicalUserId\" < \"$\{oai_file}\") || return $?",
                    "  pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\" ",
                    "  create_pseudo_stack" + " " +
                         "\"Cloudfront Origin Access Identity\"" + " " +
                         "\"$\{pseudo_stack_file}\"" + " " +
                         "\"cfaccessXs3XsegmentXops\" \"$\{oai_id}\"" + " " +
                         "\"cfaccessXs3XsegmentXopsXcanonicalid\" \"$\{oai_canonical_id}\" || return $?"
                    "}"
                    "#",
                    "case $\{STACK_OPERATION} in",
                    "  delete)",
                    "  delete_oai_credentials" + " " +
                        "\"" + regionId + "\" " +
                        "\"" + productName + "-" + segmentName + "\" || return $?",
                    "    ;;",
                    "  create|update)",
                    "    manage_oai_credentials || return $?",
                    "    ;;",
                    " esac"
                ]
        /]
    [/#if]

[/#if]


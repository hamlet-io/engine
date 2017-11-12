[#-- Standard set of buckets for an account --]
[#if deploymentUnit?contains("s3")]
    [#if deploymentSubsetRequired("s3", true)]
    
        [@cfOutput
            mode=accountListMode
            id=formatAccountDomainId()
            value=accountDomain
        /]
            
        [@cfOutput
            mode=accountListMode
            id=formatAccountDomainQualifierId()
            value=accountDomainQualifier
        /]
    
        [@cfOutput
            mode=accountListMode
            id=formatAccountDomainCertificateId()
            value=accountDomainCertificateId
        /]
        
        [#assign buckets = ["credentials", "code", "registry"] ]
        [#list buckets as bucket]
        
            [#-- TODO: Should be using formatAccountS3Id() not formatS3Id() --]
            [#-- TODO: Remove outputId parameter below when TODO addressed --]
            
            [#assign existingName = getExistingReference(formatAccountS3Id(bucket))]
            [@createS3Bucket
                mode=accountListMode
                id=formatS3Id(bucket)
                name=valueIfContent(
                        existingName,
                        existingName,
                        formatName("account", bucket, accountObject.Seed))
                outputId=formatAccountS3Id(bucket)
            /]
        [/#list]
    [/#if]
    [#if deploymentSubsetRequired("epilogue", false)]
        [#assign existingName = getExistingReference(formatAccountS3Id("code"))]
        [#assign codeBucket = valueIfContent(
                    existingName,
                    existingName,
                    formatName("account", "code", accountObject.Seed))]
        [#-- Make sure code bucket is up to date --]
        [@cfScript
            mode=applicationListMode
            content=
                [
                    "function sync_code_bucket() {",
                    "  local exit_status=",
                    "  #",
                    "  info \"Synching the code bucket ...\"",
                    "  if [[ -d \"$\{GENERATION_STARTUP_DIR}\" ]]; then",
                    "      cd \"$\{GENERATION_STARTUP_DIR}\"",
                    "      aws --region \"$\{ACCOUNT_REGION}\" s3 sync --delete --exclude=\".git*\" \"$\{GENERATION_STARTUP_DIR}/bootstrap/\" \"s3://" +
                              codeBucket + 
                              "/bootstrap/\" ||",
                    "          { exit_status=$?; fatal \"Can't sync the code bucket\"; return \"$\{exit_status}\"; }",
                    "  else",
                    "      fatal \"Startup directory not found - no sync performed\"; return 1",
                    "  fi",
                    "  return 0",
                    "}",
                    "#",
                    "case $\{STACK_OPERATION} in",
                    "  create|update)",
                    "    sync_code_bucket || return $?",
                    "    ;;",
                    " esac"
                ]
        /]
    [/#if]
[/#if]


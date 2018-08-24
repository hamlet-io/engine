[#-- Standard set of buckets for an account --]
[#if deploymentUnit?contains("s3")]
    [#if accountObject.Seed?has_content]
        [#if deploymentSubsetRequired("s3", true)]
        
            [#assign buckets = ["credentials", "code", "registry"] ]
            [#list buckets as bucket]
            
                [#-- TODO: Should be using formatAccountS3Id() not formatS3Id() --]
                [#-- TODO: Remove outputId parameter below when TODO addressed --]
                
                [#assign existingName = getExistingReference(formatAccountS3Id(bucket))]
                [@createS3Bucket
                    mode=listMode
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
            [#assign existingName = getExistingReference(formatAccountS3Id("registry"))]
            [#assign registryBucket = valueIfContent(
                        existingName,
                        existingName,
                        formatName("account", "registry", accountObject.Seed))]
            [#-- Make sure code bucket is up to date and registires initialised --]
            [@cfScript
                mode=listMode
                content=
                    [
                        "function sync_code_bucket() {",
                        "  local exit_status=",
                        "  #",
                        "  info \"Synching the code bucket ...\"",
                        "  if [[ -d \"$\{GENERATION_STARTUP_DIR}\" ]]; then",
                        "      aws --region \"$\{ACCOUNT_REGION}\" s3 sync --delete --exclude=\".git*\" \"$\{GENERATION_STARTUP_DIR}/bootstrap/\" \"s3://" +
                                  codeBucket + 
                                  "/bootstrap/\" ||",
                        "         { exit_status=$?; fatal \"Can't sync the code bucket\"; return \"$\{exit_status}\"; }",
                        "  else",
                        "      fatal \"Startup directory not found - no sync performed\"; return 1",
                        "  fi",
                        "  return 0",
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
                        "    initialise_registries \"dataset\" \"contentnode\" \"lambda\" \"pipeline\" \"scripts\" \"spa\" \"swagger\" || return $?",
                        "    ;;",
                        " esac"
                    ]
            /]
        [/#if]
    [#else]
        [@cfPreconditionFailed listMode "account_s3" {} "No account seed provided" /]
    [/#if]
[/#if]


[#ftl]
[#macro aws_user_cf_generationcontract_application occurrence ]
    [@addDefaultGenerationContract subsets=["prologue", "template", "epilogue"] /]
[/#macro]

[#macro aws_user_cf_setup_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local resources = occurrence.State.Resources]
    [#local solution = occurrence.Configuration.Solution ]

    [#local userId = resources["user"].Id ]
    [#local userName = resources["user"].Name]
    [#local apikeyId = resources["apikey"].Id ]
    [#local apikeyName = resources["apikey"].Name]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData", "AppData", "Encryption", "SSHKey" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]
    [#local cmkKeyId = baselineComponentIds["Encryption"] ]
    [#local cmkKeyArn = getExistingReference(cmkKeyId, ARN_ATTRIBUTE_TYPE)]

    [#local credentialFormats = solution.GenerateCredentials.Formats]
    [#local userPasswordLength = solution.GenerateCredentials.CharacterLength ]

    [#local managedPolicyArns = []]

    [#local passwordEncryptionScheme = (solution.GenerateCredentials.EncryptionScheme?has_content)?then(
        solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
        "" )]

    [#local encryptedSystemPassword = (
        getExistingReference(
            userId,
            PASSWORD_ATTRIBUTE_TYPE)
        )?remove_beginning(
            passwordEncryptionScheme
        )]

    [#local encryptedConsolePassword = (
        getExistingReference(
            userId,
            GENERATEDPASSWORD_ATTRIBUTE_TYPE)
        )?remove_beginning(
            passwordEncryptionScheme
        )]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#-- Add in container specifics including override of defaults --]
    [#-- Allows for explicit policy or managed ARN's to be assigned to the user --]
    [#local contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks, baselineLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : false,
            "DefaultLinkVariables" : false,
            "Policy" : standardPolicies(occurrence, baselineComponentIds)
        }
    ]

    [#if solution.Fragment?has_content ]
        [#local fragmentId = formatFragmentId(_context)]
        [#include fragmentList?ensure_starts_with("/")]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [@addToDefaultBashScriptOutput
            content=
            [
                "case $\{STACK_OPERATION} in",
                "  delete)",
                "   manage_iam_userpassword" +
                "   \"" + region + "\" " +
                "   \"delete\" " +
                "   \"" + userName + "\" || return $?",
                "   ;;",
                "esac"
            ]
        /]
        [#-- Copy any asFiles  --]
        [#local asFiles = getAsFileSettings(occurrence.Configuration.Settings.Product) ]
        [#if asFiles?has_content]
            [@debug message="Asfiles" context=asFiles enabled=false /]
            [@addToDefaultBashScriptOutput
                content=
                    findAsFilesScript("filesToSync", asFiles) +
                    syncFilesToBucketScript(
                        "filesToSync",
                        regionId,
                        operationsBucket,
                        getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX")
                    ) /]
        [/#if]
    [/#if]

    [#if _context.ManagedPolicy?has_content]
        [#local managedPolicyArns += _context.ManagedPolicy ]
    [/#if]

    [#if _context.Policy?has_content]
        [#local policyId = formatDependentManagedPolicyId(userId)]
        [#local managedPolicyArns += [ getReference(policyId, ARN_ATTRIBUTE_TYPE) ]]
        [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(policyId)]
            [@createManagedPolicy
                id=policyId
                name=_context.Name
                statements=_context.Policy
            /]
        [/#if]
    [/#if]

    [#local linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

    [#if linkPolicies?has_content]
        [#local linkPolicyId = formatDependentManagedPolicyId(userId, "links")]
        [#local managedPolicyArns += [ getReference(linkPolicyId, ARN_ATTRIBUTE_TYPE) ]]
        [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(linkPolicyId)]
            [@createManagedPolicy
                id=linkPolicyId
                name="links"
                statements=linkPolicies
            /]
         [/#if]
    [/#if]

    [#if deploymentSubsetRequired(USER_COMPONENT_TYPE, true)]
        [@cfResource
            id=userId
            type="AWS::IAM::User"
            properties=
                {
                    "UserName" : userName
                } +
                attributeIfContent(
                    "ManagedPolicyArns",
                    managedPolicyArns
                )
            outputs=USER_OUTPUT_MAPPINGS
        /]

        [#-- Manage API keys for the user if linked to usage plans --]
        [#local apikeyNeeded = false ]
        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#local linkTarget = getLinkTarget(occurrence, link, false) ]

                [@debug message="Link Target" context=linkTarget enabled=false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#local linkTargetResources = linkTarget.State.Resources ]

                [#switch linkTarget.Core.Type]
                    [#case APIGATEWAY_USAGEPLAN_COMPONENT_TYPE ]
                        [#if isLinkTargetActive(linkTarget) ]
                            [@createAPIUsagePlanMember
                                id=formatDependentResourceId(AWS_APIGATEWAY_USAGEPLAN_MEMBER_RESOURCE_TYPE, apikeyId, link.Id)
                                planId=linkTargetResources["apiusageplan"].Id
                                apikeyId=apikeyId
                            /]
                        [/#if]
                        [#local apikeyNeeded = true]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]
        [#if apikeyNeeded ]
            [@createAPIKey
                id=apikeyId
                name=apikeyName
            /]
        [/#if]
    [/#if]

    [#if deploymentSubsetRequired("epilogue", false)]

        [#local credentialsPseudoStackFile = "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-credentials-pseudo-stack.json\"" ]
        [@addToDefaultBashScriptOutput
            content=
            [
                "case $\{STACK_OPERATION} in",
                "  create|update)"
            ] +
            ( credentialFormats?seq_contains("system") && !(encryptedSystemPassword?has_content))?then(
                [
                    "# Generate IAM AccessKey",
                    "function generate_iam_accesskey() {",
                    "info \"Generating IAM AccessKey... \"",
                    "access_key=\"$(create_iam_accesskey" +
                    " \"" + region + "\" " +
                    " \"" + userName + "\" || return $?)\"",
                    "access_key_array=($access_key)",
                    "encrypted_secret_key=\"$(encrypt_kms_string" +
                    " \"" + region + "\" " +
                    " \"$\{access_key_array[1]}\" " +
                    " \"" + cmkKeyArn + "\" || return $?)\"",
                    "smtp_password=\"$(get_iam_smtp_password \"$\{access_key_array[1]}\" )\"",
                    "encrypted_smtp_password=\"$(encrypt_kms_string" +
                    " \"" + region + "\" " +
                    " \"$\{smtp_password}\" " +
                    " \"" + cmkKeyArn + "\" || return $?)\""
                ] +
                pseudoStackOutputScript(
                    "IAM User AccessKey",
                    {
                        formatId(userId, "username") : "$\{access_key_array[0]}",
                        formatId(userId, "password") : "$\{encrypted_secret_key}",
                        formatId(userId, "key") : "$\{encrypted_smtp_password}"
                    },
                    "creds-system"
                ) +
                [
                    "}",
                    "generate_iam_accesskey || return $?"
                ],
                []) +
            ( credentialFormats?seq_contains("console") && !(encryptedConsolePassword?has_content) )?then(
                [
                    "# Generate User Password",
                    "function generate_user_password() {",
                    "info \"Generating User Password... \"",
                    "user_password=\"$(generateComplexString" +
                    " \"" + userPasswordLength + "\" )\"",
                    "encrypted_user_password=\"$(encrypt_kms_string" +
                    " \"" + region + "\" " +
                    " \"$\{user_password}\" " +
                    " \"" + cmkKeyArn + "\" || return $?)\"",
                    "info \"Setting User Password... \"",
                    "manage_iam_userpassword" +
                    " \"" + region + "\" " +
                    " \"manage\" " +
                    " \"" + userName + "\" " +
                    " \"$\{user_password}\" || return $?"
                ] +
                pseudoStackOutputScript(
                    "IAM User Password",
                    {
                        formatId(userId, "generatedpassword") : "$\{encrypted_user_password}"
                    },
                    "creds-console"
                ) +
                [
                    "}",
                    "generate_user_password || return $?"
                ],
            []) +
            [
                "       ;;",
                "       esac"
            ]
        /]
    [/#if]
[/#macro]

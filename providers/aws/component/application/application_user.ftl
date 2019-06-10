[#ftl]
[#macro aws_user_cf_application occurrence ]
    [@cfDebug listMode occurrence false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["prologue", "template", "epilogue"])
        /]
        [#return]
    [/#if]

    [#local core = occurrence.Core ]
    [#local resources = occurrence.State.Resources]
    [#local solution = occurrence.Configuration.Solution ]

    [#local userId = resources["user"].Id ]
    [#local userName = resources["user"].Name]
    [#local apikeyId = resources["apikey"].Id ]
    [#local apikeyName = resources["apikey"].Name]

    [#local credentialFormats = solution.GenerateCredentials.Formats]
    [#local userPasswordLength = solution.GenerateCredentials.CharacterLength ]

    [#local segmentKMSKey = getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)]

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
    [#local _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : false,
            "DefaultLinkVariables" : false,
            "Policy" : standardPolicies(occurrence)
        }
    ]

    [#if solution.Fragment?has_content ]
        [#local fragmentListMode = "model"]
        [#local fragmentId = formatFragmentId(_context)]
        [#include fragmentList?ensure_starts_with("/")]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [@cfScript
            mode=listMode
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
    [/#if]

    [#if deploymentSubsetRequired(USER_COMPONENT_TYPE, true)]

        [#if _context.Policy?has_content]
            [#local policyId = formatDependentPolicyId(userId)]
            [@createPolicy
                mode=listMode
                id=policyId
                name=_context.Name
                statements=_context.Policy
                users=userId
            /]
        [/#if]

        [#local linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

        [#if linkPolicies?has_content]
            [#local policyId = formatDependentPolicyId(userId, "links")]
            [@createPolicy
                mode=listMode
                id=policyId
                name="links"
                statements=linkPolicies
                users=userId
            /]
        [/#if]

        [@cfResource
            mode=listMode
            id=userId
            type="AWS::IAM::User"
            properties=
                {
                    "UserName" : userName
                } +
                attributeIfContent(
                    "ManagedPolicyArns",
                    _context.ManagedPolicy![]
                )
            outputs=USER_OUTPUT_MAPPINGS
        /]

        [#-- Manage API keys for the user if linked to usage plans --]
        [#local apikeyNeeded = false ]
        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#local linkTarget = getLinkTarget(occurrence, link, false) ]

                [@cfDebug listMode linkTarget false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#local linkTargetResources = linkTarget.State.Resources ]

                [#switch linkTarget.Core.Type]
                    [#case APIGATEWAY_USAGEPLAN_COMPONENT_TYPE ]
                        [#if isLinkTargetActive(linkTarget) ]
                            [@createAPIUsagePlanMember
                                mode=listMode
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
                mode=listMode
                id=apikeyId
                name=apikeyName
            /]
        [/#if]
    [/#if]

    [#if deploymentSubsetRequired("epilogue", false)]

        [#local credentialsPseudoStackFile = "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-credentials-pseudo-stack.json\"" ]
        [@cfScript
            mode=listMode
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
                    " \"" + segmentKMSKey + "\" || return $?)\"",
                    "smtp_password=\"$(get_iam_smtp_password \"$\{access_key_array[1]}\" )\"",
                    "encrypted_smtp_password=\"$(encrypt_kms_string" +
                    " \"" + region + "\" " +
                    " \"$\{smtp_password}\" " +
                    " \"" + segmentKMSKey + "\" || return $?)\""
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
                    " \"" + segmentKMSKey + "\" || return $?)\"",
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

[#if componentType == USER_COMPONENT_TYPE]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign resources = occurrence.State.Resources]
        [#assign solution = occurrence.Configuration.Solution ]

        [#assign userId = resources["user"].Id ]
        [#assign userName = resources["user"].Name]
        [#assign apikeyId = resources["apikey"].Id ]
        [#assign apikeyName = resources["apikey"].Name]

        [#assign credentialFormats = solution.GenerateCredentials.Formats]
        [#assign userPasswordLength = solution.GenerateCredentials.CharacterLength ]

        [#assign segmentKMSKey = getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)]

        [#assign passwordEncryptionScheme = (solution.GenerateCredentials.EncryptionScheme?has_content)?then(
            solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
            "" )]

        [#assign encryptedSystemPassword = (
            getExistingReference(
                userId,
                PASSWORD_ATTRIBUTE_TYPE)
            )?remove_beginning(
                passwordEncryptionScheme
            )]

        [#assign encryptedConsolePassword = (
            getExistingReference(
                userId,
                GENERATEDPASSWORD_ATTRIBUTE_TYPE)
            )?remove_beginning(
                passwordEncryptionScheme
            )]

        [#assign fragment =
            contentIfContent(solution.Fragment, getComponentId(component)) ]

        [#-- Add in container specifics including override of defaults --]
        [#-- Allows for explicit policy or managed ARN's to be assigned to the user --]
        [#assign contextLinks = getLinkTargets(occurrence) ]
        [#assign _context =
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
            [#assign fragmentListMode = "model"]
            [#assign fragmentId = formatFragmentId(_context)]
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
                [#assign policyId = formatDependentPolicyId(userId)]
                [@createPolicy
                    mode=listMode
                    id=policyId
                    name=_context.Name
                    statements=_context.Policy
                    users=userId
                /]
            [/#if]

            [#assign linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

            [#if linkPolicies?has_content]
                [#assign policyId = formatDependentPolicyId(userId, "links")]
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
            [#assign apikeyNeeded = false ]
            [#list solution.Links?values as link]
                [#if link?is_hash]
                    [#assign linkTarget = getLinkTarget(occurrence, link, false) ]

                    [@cfDebug listMode linkTarget false /]

                    [#if !linkTarget?has_content]
                        [#continue]
                    [/#if]

                    [#assign linkTargetResources = linkTarget.State.Resources ]

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
                            [#assign apikeyNeeded = true]
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

            [#assign credentialsPseudoStackFile = "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-credentials-pseudo-stack.json\"" ]
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

    [/#list]
[/#if]

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
        [#assign context =
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
                "DefaultLinkVariables" : false
            }
        ]
        
        [#if solution.Fragment?has_content ]
            [#assign fragmentListMode = "model"]
            [#assign fragmentId = formatFragmentId(context)]
            [#assign containerId = fragmentId]
            [#include fragmentList?ensure_starts_with("/")]
        [/#if]

        [#if deploymentSubsetRequired(USER_COMPONENT_TYPE, true)]

            [#if context.Policy?has_content]
                [#assign policyId = formatDependentPolicyId(userId)]
                [@createPolicy
                    mode=listMode
                    id=policyId
                    name=context.Name
                    statements=context.Policy
                    users=userId
                /]
            [/#if]

            [#assign linkPolicies = getLinkTargetsOutboundRoles(context.Links) ]

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
                        context.ManagedPolicy![]
                    ) 
                outputs=USER_OUTPUT_MAPPINGS
            /]
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
                        "create_pseudo_stack" + " " +
                        "\"IAM User AccessKey\"" + " " +
                        "\"$\{password_pseudo_stack_file}\"" + " " +
                        "\"" + userId + "Xusername\" \"$\{access_key_array[0]}\" " +
                        "\"" + userId + "Xpassword\" \"$\{encrypted_secret_key}\" || return $?",
                        "}",
                        "password_pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-creds-system-pseudo-stack.json\" ",
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
                        "set_iam_userpassword" +
                        " \"" + region + "\" " +
                        " \"" + userName + "\" " +
                        " \"$\{user_password}\" || return $?",
                        "create_pseudo_stack" + " " +
                        "\"IAM User Password\"" + " " +
                        "\"$\{password_pseudo_stack_file}\"" + " " +
                        "\"" + userId + "Xgeneratedpassword\" \"$\{encrypted_user_password}\" || return $?",
                        "}",
                        "password_pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-creds-console-pseudo-stack.json\" ",
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
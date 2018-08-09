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

        [#assign userType = solution.Type]
        [#assign userPasswordLength = solution.GenerateCredentials.CharacterLength ]

        [#assign segmentKMSKey = getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)]

        [#assign passwordEncryptionScheme = (solution.GenerateCredentials.EncryptionScheme?has_content)?then(
            solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
            "" )]

        [#assign encryptedPassword = (
            getExistingReference(
                userId, 
                PASSWORD_ATTRIBUTE_TYPE)
            )?remove_beginning(
                passwordEncryptionScheme
            )]


        [#assign containerId =
            solution.Container?has_content?then(
                solution.Container,
                getComponentId(component)
            ) ]
        
        [#-- Add in container specifics including override of defaults --]
        [#-- Allows for explicit policy or managed ARN's to be assigned to the user --]
        [#assign contextLinks = getLinkTargets(occurrence) ]
        [#assign context =
            {
                "Id" : containerId,
                "Name" : containerId,
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
        
        [#if solution.Container?has_content ]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(occurrence, context)]
            [#include containerList?ensure_starts_with("/")]
        [/#if]

        [#if deploymentSubsetRequired(USER_COMPONENT_TYPE, true)]
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
                    ) + 
                    attributeIfContent(
                        "Policies",
                        context.Policy![]
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
                ( userType?lower_case == "system" && !(encryptedPassword?has_content))?then(
                    [
                        "# Generate IAM AccessKey",
                        "function generate_iam_accesskey() {",
                        "info \"Generating IAM AccessKey... \"",
                        "access_key=\"$(create_iam_accesskey" +
                        " \"" + region + "\" " +
                        " \"" + userName + "\" )\"",
                        "encrypted_secret_key=\"$(encrypt_kms_string" +
                        " \"" + region + "\" " +
                        " \"$\{access_key[1]}\" " +
                        " \"" + segmentKMSKey + "\" || return $?)\"",
                        "create_pseudo_stack" + " " +
                        "\"IAM User AccessKey\"" + " " +
                        "\"$\{password_pseudo_stack_file}\"" + " " +
                        "\"" + userId + "Xusername\" \"$\{access_key[0]}\" " +
                        "\"" + userId + "Xpassword\" \"$\{encrypted_secret_key}\" || return $?",
                        "}",
                        "password_pseudo_stack_file=" + credentialsPseudoStackFile,
                        "generate_iam_accesskey || return $?"
                    ],
                    []) +
                ( userType?lower_case == "user" && !(encryptedPassword?has_content) )?then(
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
                        "password_pseudo_stack_file=" + credentialsPseudoStackFile,
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
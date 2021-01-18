[#ftl]

[@addComponentDeployment
    type=USERPOOL_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=USERPOOL_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Managed identity service"
            },
            {
                "Type" : "Note",
                "Value" : "Make sure to plan your schema before initial deployment. Updating shema attributes causes a replaccement of the userpool",
                "Severity" : "warning"
            },
            {
                "Type" : "Note",
                "Value" : "Please read https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-add-custom-domain.html before enabling custom domains on userpool hosted UI. An A Record is required in your base domain",
                "Severity" : "warning"
            }
        ]
    attributes=
        [
            {
                "Names" : "MFA",
                "Type" : [ BOOLEAN_TYPE, STRING_TYPE],
                "Values" : [ "true", true, "false", false, "optional" ],
                "Default" : false
            },
            {
                "Names" : "MFAMethods",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Values" : [ "SMS", "SoftwareToken" ],
                "Default" : [ "SMS" ]
            },
            {
                "Names" : "AdminCreatesUser",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "UnusedAccountTimeout",
                "Type" : NUMBER_TYPE,
                "Default" : 1
            },
            {
                "Names" : "VerifyEmail",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "VerifyPhone",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "LoginAliases",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Description" : "Deprecated - use Username.Aliases"
            },
            {
                "Names" : "AuthorizationHeader",
                "Type" : STRING_TYPE,
                "Default" : "Authorization"
            },
            {
                "Names" : "Username",
                "Children" : [
                    {
                        "Names" : "CaseSensitive",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Attributes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Values" : [ "email", "phone_number" ],
                        "Default" : [ ]
                    },
                    {
                        "Names" : "Aliases",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Values" : [ "phone_number", "email", "preferred_username" ],
                        "Default" : ["email"]
                    }
                ]
            }
            {
                "Names" : "PasswordPolicy",
                "Children" : [
                    {
                        "Names" : "AllowUserRecovery",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "MinimumLength",
                        "Type" : NUMBER_TYPE,
                        "Default" : 10
                    },
                    {
                        "Names" : "Lowercase",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Uppercase",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Numbers",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "SpecialCharacters",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "DefaultClient",
                "Type" : BOOLEAN_TYPE,
                "Description" : "Enable default client mode which creates app client for the user pool and aligns with legacy config",
                "Default" : true
            },
            {
                "Names" : "Schema",
                "Subobjects" : true,
                "Children" :    [
                    {
                        "Names" : "DataType",
                        "Values" : [ "String", "Number", "DateTime","Boolean"],
                        "Type" : STRING_TYPE,
                        "Default" : "String"
                    },
                    {
                        "Names" : "Mutable",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Required",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "HostedUI",
                "Description" : "Provision a managed endpoint for login and oauth endpoints",
                "Children" : [
                    {
                        "Names" : "Certificate",
                        "Children" : certificateChildConfiguration
                    }
                ]
            },
            {
                "Names" : "Security",
                "Children" : [
                    {
                        "Names" : "UserDeviceTracking",
                        "Type" : [ BOOLEAN_TYPE, STRING_TYPE],
                        "Values" : [ "true", true, "false", false, "optional" ],
                        "Default" : "optional"
                    },
                    {
                        "Names" : "ActivityTracking",
                        "Description" : "Apply authentication validation based on activity",
                        "Type" : STRING_TYPE,
                        "Values" : [ "disabled", "audit", "enforced" ],
                        "Default" : "disabled"
                    }
                ]
            },
            {
                "Names" : "VerificationEmailType",
                "Description" : "The default verification email option for message customization.",
                "Values" : [ "code", "link"],
                "Type" : STRING_TYPE,
                "Default" : "code"
            }
        ]
/]

[@addChildComponent
    type=USERPOOL_CLIENT_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A oauth app client which belongs to the userpool"
            }
        ]
    attributes=
        [
            {
                "Names" : "OAuth",
                "Children" : [
                    {
                        "Names" : "Scopes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Values" : [ "phone", "email", "openid", "aws.cognito.signin.user.admin", "profile" ],
                        "Default" : [ "email", "openid" ]
                    },
                    {
                        "Names" : "Flows",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Values" : [ "code", "implicit", "client_credentials" ],
                        "Default" : [ "code" ]
                    },
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "ClientGenerateSecret",
                "Description" : "Generate a client secret which musht be provided in auth calls",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "EncryptionScheme",
                "Type" : STRING_TYPE,
                "Description" : "A prefix appended to attributes to show encryption status",
                "Default" : ""
            },
            {
                "Names" : "ClientTokenValidity",
                "Description" : "Time in days that the refresh token is valid for",
                "Type" : NUMBER_TYPE,
                "Default" : 30
            },
            {
                "Names" : "AuthProviders",
                "Description" : "A list of user pool auth providers which can use this client",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "COGNITO" ]
            },
            {
                "Names" : "ResourceScopes",
                "Description" : "Resources that the client is permitted to access",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Name",
                        "Type" : STRING_TYPE,
                        "Description" : "The name of a userpool resource configured for this pool",
                        "Mandatory" : true
                    },
                    {
                        "Names" : "Scopes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Description" : "A list of scopes that the resource offers",
                        "Mandatory" : true
                    }
                ]
            }
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    parent=USERPOOL_COMPONENT_TYPE
    childAttribute="Clients"
    linkAttributes="Client"
/]

[@addChildComponent
    type=USERPOOL_AUTHPROVIDER_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An external auth provider which will federate with the user pool"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Description" : "The authentication provider type",
                "Type" : STRING_TYPE,
                "Values" : [ "SAML", "OIDC", "Facebook", "Google", "Apple", "Amazon" ],
                "Mandatory" : true
            },
            {
                "Names" : "SettingsPrefix",
                "Description" : "A prefix to use for this providers settings lookup",
                "Type": STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "EncryptionScheme",
                "Type" : STRING_TYPE,
                "Default" : "base64:"
            },
            {
                "Names" : "AttributeMappings",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "UserPoolAttribute",
                        "Description" : "The name of the attribute in the user pool schema - the id of the mapping will be used if not provided",
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "ProviderAttribute",
                        "Description" : "The provider attribute which will be mapped",
                        "Type" : STRING_TYPE,
                        "Mandatory" : true
                    }
                ]
            },
            {
                "Names" : "IDPIdentifiers",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Description" : "A list of identifiers that can be used to automatically pick the IDP - E.g. email domain",
                "Default" : []
            },
            {
                "Names" : "SAML",
                "Children" : [
                    {
                        "Names" : "MetadataUrl",
                        "Description" : "The SAML metadataUrl endpoint",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "EnableIDPSignOut",
                        "Description" : "Enable the IDP Signout Flow",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "OIDC",
                "Children" : [
                    {
                        "Names" : "ClientId",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "ClientSecret",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Scopes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "openid", "email" ]
                    },
                    {
                        "Names" : "AttributesHttpMethod",
                        "Type" : STRING_TYPE,
                        "Values" : [ "GET", "POST" ],
                        "Default" : "GET"
                    },
                    {
                        "Names" : "Issuer",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "AuthorizeUrl",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "TokenUrl",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "AttributesUrl",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "JwksUrl",
                        "Type" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Facebook",
                "Children" : [
                    {
                        "Names" : "ClientId",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "ClientSecret",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Scopes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "email", "public_profile" ]
                    },
                    {
                        "Names" : "APIVersion",
                        "Type" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Amazon",
                "Children" : [
                    {
                        "Names" : "ClientId",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "ClientSecret",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Scopes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "profile" ]
                    }
                ]
            },
            {
                "Names" : "Google",
                "Children" : [
                    {
                        "Names" : "ClientId",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "ClientSecret",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Scopes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "openid", "profile", "email"  ]
                    }
                ]
            },
            {
                "Names" : "Apple",
                "Children" : [
                    {
                        "Names" : "ClientId",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "TeamId",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "KeyId",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "PrivateKey",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Scopes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "email", "name"  ]
                    }
                ]
            }
        ]
    parent=USERPOOL_COMPONENT_TYPE
    childAttribute="AuthProviders"
    linkAttributes="AuthProvider"
/]


[@addChildComponent
    parent=USERPOOL_COMPONENT_TYPE
    type=USERPOOL_RESOURCE_COMPONENT_TYPE
    childAttribute="Resources"
    linkAttributes="Resource"
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A resource represents a server protected by the userpool and the scoped roles that it offers"
            }
        ]
    attributes=
        [
            {
                "Names" : "Server",
                "Description" : "The endpoint of the resource",
                "Mandatory" : true,
                "Children" : [
                    {
                        "Names" : "Link",
                        "Description" : "A link to the server resource represented by this resource",
                        "Mandatory" : true,
                        "Children" : linkChildrenConfiguration
                    },
                    {
                        "Names" : "LinkAttribute",
                        "Types" : STRING_TYPE,
                        "Description" : "The link targets attribute which defines the url",
                        "Default" : "URL"
                    },
                    {
                        "Names" : "UseProvidedScopes",
                        "Description" : "Use Scopes provided by the server component if available",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Scopes",
                "Description" : "The access scopes offered by the server",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Name",
                        "Description" : "The name of the scope which is passed to the server",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Description",
                        "Description" : "A short description of the scope and what it does",
                        "Type" : STRING_TYPE
                    }
                ]
            }
        ]

/]

[#ftl]

[@addComponent
    type=USERPOOL_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Managed identity service"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
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
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AdminCreatesUser",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "UnusedAccountTimeout",
                "Type" : NUMBER_TYPE,
                "Default" : 7
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
                "Default" : ["email"]
            },
            {
                "Names" : "AuthorizationHeader",
                "Type" : STRING_TYPE,
                "Default" : "Authorization"
            },
            {
                "Names" : "PasswordPolicy",
                "Children" : [
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
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
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
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Description" : "The authentication provider type",
                "Type" : STRING_TYPE,
                "Values" : [ "SAML", "OIDC" ],
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
                        "Type" : STRING_TYPE,
                        "Default" : ""
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
                        "Type" : STRING_TYPE,
                        "Default" : "" 
                    },
                    {
                        "Names" : "ClientSecret",
                        "Type" : STRING_TYPE,
                        "Default" : "" 
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
                        "Type" : STRING_TYPE,
                        "Default" : "" 
                    },
                    {
                        "Names" : "AuthorizeUrl",
                        "Type" : STRING_TYPE,
                        "Default" : "" 
                    },
                    {
                        "Names" : "TokenUrl",
                        "Type" : STRING_TYPE,
                        "Default" : "" 
                    },
                    {
                        "Names" : "AttributesUrl",
                        "Type" : STRING_TYPE,
                        "Default" : "" 
                    },
                    {
                        "Names" : "JwksUrl",
                        "Type" : STRING_TYPE,
                        "Default" : "" 
                    }
                ]
            }
        ]
    parent=USERPOOL_COMPONENT_TYPE
    childAttribute="AuthProviders"
    linkAttributes="AuthProvider"
/]

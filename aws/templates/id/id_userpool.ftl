[#-- Cognito UserPool --]

[#-- Resources --]
[#assign AWS_COGNITO_USERPOOL_RESOURCE_TYPE = "userpool"]
[#assign AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE = "userpoolclient"]
[#assign AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE = "identitypool"]
[#assign AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE = "rolemapping"]
[#assign AWS_COGNITO_USERPOOL_DOMAIN_RESOURCE_TYPE = "userpooldomain" ]

[#-- Components --]
[#assign USERPOOL_COMPONENT_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_COMPONENT_TYPE = "userpoolclient" ]
[#assign USERPOOL_COMPONENT_ROLE_UNAUTH_EXTENSTION = "unauth" ]
[#assign USERPOOL_COMPONENT_ROLE_AUTH_EXTENSTION = "auth" ]

[#assign componentConfiguration +=
    {
        USERPOOL_COMPONENT_TYPE : {
            "Properties" : [
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
            ],
            "Attributes" : [
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
                    "Names" : "AllowUnauthenticatedIds",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
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
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
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
                    "Description" : "Provsion a managed endpoint for login and oauth endpoints",
                    "Children" : [
                        {
                            "Names" : "Certificate",
                            "Children" : certificateChildConfiguration
                        }
                    ]
                }
            ],
            "Components" : [
                {
                    "Type" : USERPOOL_CLIENT_COMPONENT_TYPE,
                    "Component" : "Clients",
                    "Link" : [ "Client" ]
                }
            ]
        },
        USERPOOL_CLIENT_COMPONENT_TYPE : {
            "Properties" : [
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
            ],
            "Attributes" : [
                {
                    "Names" : "OAuth",
                    "Children" : [
                        {
                            "Names" : "Scopes",
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Values" : [ "phone", "email", "openid", "Cognito" ],
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
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "ClientTokenValidity",
                    "Type" : NUMBER_TYPE,
                    "Default" : 30
                },
                {
                    "Names" : "IdentityPoolAccess",
                    "Description" : "Enable the use of the identity pool for this client",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                }
            ]
        }
    }]
    
[#function getUserPoolState occurrence baseState]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#if core.External!false]
        [#local id = baseState.Attributes["USER_POOL_ARN"]!"" ]
        [#return
            baseState +
            valueIfContent(
                {
                    "Roles" : {
                        "Inbound" : {
                            "invoke" : {
                                "Principal" : "cognito-idp.amazonaws.com",
                                "SourceArn" : id
                            }
                        },
                        "Outbound" : {
                        }
                    }
                },
                id,
                {
                    "Roles" : {
                        "Inbound" : {},
                        "Outbound" : {}
                    }
                }
            )
        ]
    [#else]

        [#local userPoolId = formatResourceId(AWS_COGNITO_USERPOOL_RESOURCE_TYPE, core.Id)]
        [#local userPoolName = formatSegmentFullName(core.Name)]
        
        [#local defaultUserPoolClientId = formatResourceId(AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE, core.Id) ]
        [#local defaultUserPoolClientName = formatSegmentFullName(core.Name)]
        [#local defaultUserPoolClientRequired = solution.DefaultClient ]
        
        [#local identityPoolId = formatResourceId(AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE, core.Id)]
        [#local identityPoolName = formatSegmentFullName(core.Name)?replace("-","X")]

        [#local identityPoolRoleMappingId = formatDependentResourceId(AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE, identityPoolId)]

        [#local userPoolRoleId = formatComponentRoleId(core.Tier, core.Component)]

        [#local identityPoolUnAuthRoleId = formatDependentRoleId(identityPoolId,USERPOOL_COMPONENT_ROLE_UNAUTH_EXTENSTION )]
        [#local identityPoolAuthRoleId = formatDependentRoleId(identityPoolId,USERPOOL_COMPONENT_ROLE_AUTH_EXTENSTION )]

        [#local userPoolDomainId = formatResourceId(AWS_COGNITO_USERPOOL_DOMAIN_RESOURCE_TYPE, core.Id)]
        [#local certificatePresent = isPresent(solution.HostedUI.Certificate) ]
        [#local userPoolDomainName = formatName("auth", core.ShortFullName, segmentSeed)]
        [#local userPoolBaseUrl = "https://" + formatDomainName(userPoolDomainName, "auth", region, "amazoncognito.com") + "/" ]

        [#local region = getExistingReference(userPoolId, REGION_ATTRIBUTE_TYPE)!regionId ]

        [#local certificateArn = ""]
        [#if certificatePresent ]
            [#local certificateObject = getCertificateObject(solution.HostedUI.Certificate!"", segmentQualifiers)]
            [#local certificateDomains = getCertificateDomains(certificateObject) ]
            [#local primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
            [#local hostName = getHostName(certificateObject, occurrence) ]
            [#local userPoolCustomDomainName = formatDomainName(hostName, primaryDomainObject)]
            [#local userPoolCustomBaseUrl = "https://" + userPoolDomainName + "/" ] 

            [#local certificateId = formatDomainCertificateId(certificateObject, userPoolDomainName)]
            [#local certificateArn = (getExistingReference(certificateId, ARN_ATTRIBUTE_TYPE, "us-east-1" )?has_content)?then(
                                            getExistingReference(certificateId, ARN_ATTRIBUTE_TYPE, "us-east-1" ),
                                            "COTException: ACM Certificate required in us-east-1"
                                    )]
        [/#if]

        [#return
            {
                "Resources" : {
                    "userpool" : {
                        "Id" : userPoolId,
                        "Name" : userPoolName,
                        "Type" : AWS_COGNITO_USERPOOL_RESOURCE_TYPE
                    },
                    "domain" : {
                        "Id" : userPoolDomainId,
                        "Name" : userPoolDomainName,
                        "Type" : AWS_COGNITO_USERPOOL_DOMAIN_RESOURCE_TYPE
                    },
                    "identitypool" : { 
                        "Id" : identityPoolId,
                        "Name" : identityPoolName,
                        "Type" : AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE
                    },
                    "userpoolrole" : {
                        "Id" : userPoolRoleId,
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                    },
                    "unauthrole" : { 
                        "Id" : identityPoolUnAuthRoleId,
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                    },
                    "authrole" : {
                        "Id" : identityPoolAuthRoleId,
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                    },
                    "rolemapping" : {
                        "Id" : identityPoolRoleMappingId,
                        "Type" : AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE
                    }
                } + 
                defaultUserPoolClientRequired?then(
                    {
                        "client" : {
                            "Id" : defaultUserPoolClientId,
                            "Name" : defaultUserPoolClientName,
                            "Type" : AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE
                        }
                    },
                    {}
                ) +
                certificatePresent?then(
                    {
                        "customdomain" : {
                            "Id" : formatId(userPoolDomainId, "custom"),
                            "Name" : userPoolCustomDomainName,
                            "CertificateArn" : certificateArn,
                            "Type" : AWS_COGNITO_USERPOOL_DOMAIN_RESOURCE_TYPE
                        }
                    },
                    {}
                ),
                "Attributes" : {
                    "AUTHORIZATION_HEADER" : occurrence.Configuration.Solution.AuthorizationHeader,
                    "USER_POOL" : getExistingReference(userPoolId),
                    "IDENTITY_POOL" : getExistingReference(identityPoolId),
                    "REGION" : region,
                    "UI_INTERNAL_BASE_URL" : userPoolBaseUrl,
                    "UI_BASE_URL" : userPoolCustomBaseUrl!userPoolBaseUrl
                } + 
                defaultUserPoolClientRequired?then(
                    {
                        "CLIENT" : getExistingReference(defaultUserPoolClientId)
                    },
                    {}
                ),
                "Roles" : {
                    "Inbound" : {
                        "invoke" : {
                            "Principal" : "cognito-idp.amazonaws.com",
                            "SourceArn" : getReference(userPoolId,ARN_ATTRIBUTE_TYPE)
                        }
                    },
                    "Outbound" : {}
                }
            }
        ]
    [/#if]
[/#function]

[#function getUserPoolClientState occurrence parent ]
    [#local core = occurrence.Core]

    [#assign userPoolClientId = formatResourceId(AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE, core.Id)]
    [#assign userPoolClientName = formatSegmentFullName(core.Name)]

    [#local parentAttributes = parent.State.Attributes ]
    [#local parentResources = parent.State.Resources ]

    [#if core.SubComponent.Id = "default" && (parentResources["client"]!{})?has_content ]
        [#local userPoolClientId    = parentResources["client"].Id ]
        [#local userPoolClientName  = parentResources["client"].Name ]
    [/#if]    

    [#return
        {
            "Resources" : {
                "client" : {
                    "Id" : userPoolClientId,
                    "Name" : userPoolClientName,
                    "Type" : AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "CLIENT" : getReference(userPoolClientId)
            } + 
            parentAttributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }]
[/#function]
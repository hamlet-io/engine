[#ftl]

[#macro aws_userpool_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]

    [#if core.External!false]
        [#local id = baseState.Attributes["USERPOOL_ARN"]!"COTFatal: External Userpool ARN Not configured" ]
        [#local FQDN = ((baseState.Attributes["USERPOOL_BASE_URL"])!"")?remove_beginning("https://")?remove_ending("/")]
        [#assign componentState =
            baseState +
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
                },
                "Attributes" : {
                    "USER_POOL_ARN" : baseState.Attributes["USERPOOL_ARN"],
                    "USER_POOL_NAME" : baseState.Attributes["USERPOOL_NAME"],
                    "CLIENT" : baseState.Attributes["USERPOOL_CLIENTID" ]!"",
                    "USER_POOL" : baseState.Attributes["USERPOOL_ID"]!"",
                    "IDENTITY_POOL" : baseState.Attributes["USERPOOL_IDENTITYPOOL_ID"]!"",
                    "REGION" : baseState.Attributes["USERPOOL_REGION"]!region,
                    "UI_INTERNAL_BASE_URL" : baseState.Attributes["USERPOOL_BASE_URL"]!"",
                    "UI_INTERNAL_FQDN" : FQDN,
                    "UI_BASE_URL" : baseState.Attributes["USERPOOL_BASE_URL"]!"",
                    "UI_FQDN" : FQDN,
                    "API_AUTHORIZATION_HEADER" : baseState.Attributes["USERPOOL_AUTHORIZATION_HEADER"]!"Authorization",
                    "LB_OAUTH_SCOPE" : baseState.Attributes["USERPOOL_OAUTH_SCOPE"]!"",
                    "AUTH_USERROLE_ARN" : baseState.Attributes["USERPOOL_USERROLE_ARN"]!""
                }
            }
        ]
    [#else]
        [#local solution = occurrence.Configuration.Solution]

        [#local userPoolId = formatResourceId(AWS_COGNITO_USERPOOL_RESOURCE_TYPE, core.Id)]
        [#local userPoolName = formatSegmentFullName(core.Name)]

        [#local defaultUserPoolClientId = formatResourceId(AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE, core.Id) ]
        [#local defaultUserPoolClientName = formatSegmentFullName(core.Name)]
        [#local defaultUserPoolClientRequired = solution.DefaultClient ]

        [#local userPoolRoleId = formatComponentRoleId(core.Tier, core.Component)]

        [#local userPoolDomainId = formatResourceId(AWS_COGNITO_USERPOOL_DOMAIN_RESOURCE_TYPE, core.Id)]
        [#local certificatePresent = isPresent(solution.HostedUI.Certificate) ]
        [#local userPoolDomainName = formatName("auth", core.ShortFullName, segmentSeed)]
        [#local userPoolFQDN = formatDomainName(userPoolDomainName, "auth", region, "amazoncognito.com")]
        [#local userPoolBaseUrl = "https://" + userPoolFQDN + "/" ]

        [#local region = getExistingReference(userPoolId, REGION_ATTRIBUTE_TYPE)!regionId ]

        [#local certificateArn = ""]
        [#if certificatePresent ]
            [#local certificateObject = getCertificateObject(solution.HostedUI.Certificate!"", segmentQualifiers)]
            [#local certificateDomains = getCertificateDomains(certificateObject) ]
            [#local primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
            [#local hostName = getHostName(certificateObject, occurrence) ]
            [#local userPoolCustomDomainName = formatDomainName(hostName, primaryDomainObject)]
            [#local userPoolCustomBaseUrl = "https://" + userPoolCustomDomainName + "/" ]

            [#local certificateId = formatDomainCertificateId(certificateObject, userPoolDomainName)]
            [#local certificateArn = (getExistingReference(certificateId, ARN_ATTRIBUTE_TYPE, "us-east-1" )?has_content)?then(
                                            getExistingReference(certificateId, ARN_ATTRIBUTE_TYPE, "us-east-1" ),
                                            "COTFatal: ACM Certificate required in us-east-1"
                                    )]
        [/#if]

        [#assign componentState =
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
                    "API_AUTHORIZATION_HEADER" : occurrence.Configuration.Solution.AuthorizationHeader,
                    "USER_POOL" : getExistingReference(userPoolId),
                    "USER_POOL_NAME" : getExistingReference(userPoolId, NAME_ATTRIBUTE_TYPE),
                    "USER_POOL_ARN" : getExistingReference(userPoolId, ARN_ATTRIBUTE_TYPE),
                    "REGION" : region,
                    "UI_INTERNAL_BASE_URL" : userPoolBaseUrl,
                    "UI_INTERNAL_FQDN" : userPoolFQDN,
                    "UI_BASE_URL" : userPoolCustomBaseUrl!userPoolBaseUrl,
                    "UI_FQDN" : userPoolCustomDomainName!userPoolFQDN
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
[/#macro]

[#macro aws_userpoolclient_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local userPoolClientId = formatResourceId(AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE, core.Id)]
    [#local userPoolClientName = formatSegmentFullName(core.Name)]

    [#local parentAttributes = parent.State.Attributes ]
    [#local parentResources = parent.State.Resources ]

    [#if core.SubComponent.Id = "default" && (parentResources["client"]!{})?has_content ]
        [#local userPoolClientId    = parentResources["client"].Id ]
        [#local userPoolClientName  = parentResources["client"].Name ]
    [/#if]

    [#assign componentState =
        {
            "Resources" : {
                "client" : {
                    "Id" : userPoolClientId,
                    "Name" : userPoolClientName,
                    "Type" : AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "CLIENT" : getReference(userPoolClientId),
                "LB_OAUTH_SCOPE" : (solution.OAuth.Scopes)?join(", ")
            } +
            parentAttributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }]
[/#macro]

[#macro aws_userpoolauthprovider_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]

    [#local authProviderId = formatResourceId(AWS_COGNITO_USERPOOL_AUTHPROVIDER_RESOURCE_TYPE, core.Id)]
    [#local authProviderName = core.SubComponent.Name]

    [#assign componentState =
        {
            "Resources" : {
                "authprovider" : {
                    "Id" : authProviderId,
                    "Name" : authProviderName,
                    "Type" : AWS_COGNITO_USERPOOL_AUTHPROVIDER_RESOURCE_TYPE,
                    "Deployed" : true
                }
            },
            "Attributes" : {
                "PROVIDER_NAME" : authProviderName
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }]
[/#macro]

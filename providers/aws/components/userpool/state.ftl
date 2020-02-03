[#ftl]

[#macro aws_userpool_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]

    [#if core.External!false]
        [#local attrUserPoolId = occurrence.State.Attributes["USERPOOL_ID"]!"" ]
        [#local attrUserPoolArn = occurrence.State.Attributes["USERPOOL_ARN"]!"COTFatal: External Userpool ARN Not configured"]
        [#local attrUserPoolName = occurrence.State.Attributes["USERPOOL_NAME"]!"" ]
        [#local attrUserPoolRegion = occurrence.State.Attributes["USERPOL_REGION"]!region ]

        [#local attrClientId = occurrence.State.Attributes["USERPOOL_CLIENTID"]!"" ]

        [#local attrUIBaseURL = occurrence.State.Attributes["USERPOOL_BASE_URL"]!"" ]
        [#local attrUIFQDN = attrUIBaseURL?remove_beginning("https://")?remove_ending("/")]
        [#local attrUIInternalBaseUrl = attrUIBaseURL ]
        [#local attrUIInternalFQDN = attrUIFQDN ]

        [#local attrLbAuthHeader =  occurrence.State.Attributes["USERPOOL_AUTHORIZATION_HEADER"]!"Authorization"]

        [#assign componentState =
            {
                "Roles" : {
                    "Inbound" : {
                        "invoke" : {
                            "Principal" : "cognito-idp.amazonaws.com",
                            "SourceArn" : attrUserPoolArn
                        }
                    },
                    "Outbound" : {
                    }
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
            [#local certificateArn = getExistingReference(certificateId, ARN_ATTRIBUTE_TYPE, "us-east-1")]
        [/#if]

        [#local attrUserPoolId = getExistingReference(userPoolId) ]
        [#local attrUserPoolArn = getExistingReference(userPoolId, ARN_ATTRIBUTE_TYPE) ]
        [#local attrUserPoolName = getExistingReference(userPoolId, NAME_ATTRIBUTE_TYPE) ]
        [#local attrUserPoolRegion = region]

        [#local attrClientId = defaultUserPoolClientRequired?then(
                                    getExistingReference(defaultUserPoolClientId),
                                    "")]

        [#local attrUIBaseURL = userPoolCustomBaseUrl!userPoolBaseUrl ]
        [#local attrUIFQDN = userPoolCustomDomainName!userPoolFQDN ]
        [#local attrUIInternalBaseUrl = userPoolBaseUrl ]
        [#local attrUIInternalFQDN = userPoolFQDN ]

        [#local attrLbAuthHeader =  occurrence.Configuration.Solution.AuthorizationHeader ]

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
                    },
                    "role" : {
                        "Id" : formatComponentRoleId(core.Tier, core.Component),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
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

    [#assign componentState +=
        {
            "Attributes" : {
                "USER_POOL" : attrUserPoolId,
                "USER_POOL_NAME" : attrUserPoolName,
                "USER_POOL_ARN" : attrUserPoolArn,
                "REGION" : attrUserPoolRegion,
                "UI_INTERNAL_BASE_URL" : attrUIInternalBaseUrl,
                "UI_INTERNAL_FQDN" : attrUIInternalFQDN,
                "UI_BASE_URL" : attrUIBaseURL,
                "UI_FQDN" : attrUIFQDN,
                "API_AUTHORIZATION_HEADER" : attrLbAuthHeader
            } +
            attributeIfContent(
                "CLIENT",
                attrClientId
            )
        }
    ]
[/#macro]

[#macro aws_userpoolclient_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local userPoolClientId = formatResourceId(AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE, core.Id)]
    [#local userPoolClientName = formatSegmentFullName(core.Name)]

    [#local parentAttributes = parent.State.Attributes ]
    [#local parentResources = parent.State.Resources ]

    [#if core.SubComponent.Id == "default" && (parentResources["client"]!{})?has_content ]
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
            "Attributes" :
            parentAttributes +
            {
                "CLIENT" : getExistingReference(userPoolClientId),
                "LB_OAUTH_SCOPE" : (solution.OAuth.Scopes)?join(", ")
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }]
[/#macro]

[#macro aws_userpoolauthprovider_cf_state occurrence parent={} ]
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

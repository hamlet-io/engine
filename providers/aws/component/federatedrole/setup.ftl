[#ftl]
[#macro aws_federatedrole_cf_solution occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]

    [#local identityPoolId = resources["identitypool"].Id ]
    [#local identityPoolName = resources["identitypool"].Name ]
    
    [#local roleMappingId = resources["rolemapping"].Id ]
    
    [#local fragment = getOccurrenceFragmentBase(occurrence) ]
    [#local _parentContext =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id
        }
    ]
    [#local fragmentId = formatFragmentId(_parentContext)]

    [#local federationProviders = {}]
    [#local federationCognitoProviders = [] ]

    [#list solution.Links as id,link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget( occurrence, link ) ]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case USERPOOL_CLIENT_COMPONENT_TYPE ]
                [#case USERPOOL_COMPONENT_TYPE ]

                    [#local userPoolName = linkTargetAttributes["USER_POOL_NAME"] ]
                    [#local userPoolClient = linkTargetAttributes["CLIENT"] ]

                    [#local federationProviders +=  
                                {
                                    id : { 
                                        "Provider" : concatenate( [ userPoolName, userPoolClient], ":" ),
                                        "Rules" : []
                                    }
                                }]

                    [#local federationCognitoProviders += 
                                getIdentityPoolCognitoProvider( 
                                    userPoolName,
                                    userPoolClient
                                )]  
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#if deploymentSubsetRequired(USERPOOL_COMPONENT_TYPE, true) ]
        [@createIdentityPool
            mode=listMode
            id=identityPoolId
            name=identityPoolName
            cognitoIdProviders=federationCognitoProviders
            allowUnauthenticatedIdentities=solution.AllowUnauthenticatedUsers
        /]
    [/#if]

    [#-- Assignment Management --]
    [#local authenticatedRole= ""]
    [#local unauthenticatedRole = ""]
    [#local ruleAssignments = {} ]

    [#list occurrence.Occurrences![] as subOccurrence]

        [#local subCore = subOccurrence.Core ]
        [#local subSolution = subOccurrence.Configuration.Solution ]
        [#local subResources = subOccurrence.State.Resources ]

        [#if !subSolution.Enabled]
            [#continue]
        [/#if]

        [#local roleId = subResources["role"].Id ]

        [#local contextLinks = getLinkTargets(subOccurrence)]

        [#assign _context =
            {
                "Id" : fragment,
                "Name" : fragment,
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "Links" : contextLinks,
                "Policy" : standardPolicies(subOccurrence),
                "ManagedPolicy" : [],
                "Assignment" : subCore.SubComponent.Id
            }
        ]

        [#switch subSolution.Type ]
            [#case "Authenticated" ]
                [#if ! authenticatedRole?has_content ]
                    [#local authenticatedRole = roleId ]
                [#else]
                    [@cfException
                        mode=listMode
                        description="Only one assignment of this type is possible"
                        context=
                            {
                                "Type" : subSolution.Type,
                                "Asignment" : subOccurrence
                            }
                    /]
                [/#if]
                [#break]

            [#case "Unauthenticated" ]
                [#if ! unauthenticatedRole?has_content ]
                    [#local unauthenticatedRole = roleId ]
                [#else]
                    [@cfException
                        mode=listMode
                        description="Only one assignment of this type is possible"
                        context=
                            {
                                "Type" : subSolution.Type,
                                "Asignment" : subOccurrence
                            }
                    /]
                [/#if]
                [#break]

            [#case "Rule" ]

                [#local mappingRule = getIdentityPoolMappingRule( 
                                            (subSolution.Rule.Priority + subOccurrence?counter),
                                            subSolution.Rule.Claim,
                                            subSolution.Rule.MatchType,
                                            subSolution.Rule.Value,
                                            roleId
                                    )]

                [#list subSolution.Rule.Providers as provider ]
                    [#local federationProvider = federationProviders[ provider ]]
                    [#if federationProvider?has_content]  
                    
                        [#local federationProviderRules = federationProvider["Rules"] + mappingRule ]

                        
                        [#local federationProviders = mergeObjects( federationProviders, 
                                                            {
                                                                provider : {
                                                                    "Rules" : federationProviderRules 
                                                                }
                                                            }
                        
                        )]
                    [/#if]
                [/#list]
                    
                [#break]
        [/#switch]

        [#-- Add in fragment specifics including override of defaults --]
        [#assign fragmentListMode = "model"]
        [#include fragmentList?ensure_starts_with("/")]

        [#local managedPolicies = _context.ManagedPolicy ]
        [#local linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

        [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]

            [@createRole
                mode=listMode
                id=roleId
                federatedServices="cognito-identity.amazonaws.com"
                condition={
                    "StringEquals": {
                        "cognito-identity.amazonaws.com:aud": getReference(identityPoolId)
                    },
                    "ForAnyValue:StringLike": {
                        "cognito-identity.amazonaws.com:amr": valueIfTrue(
                                                                "unauthenticated",
                                                                subCore.Type == "Unauthenticated",
                                                                "authenticated"
                        )
                    }
                }
                managedArns=managedPolicies
            /]

            [#if _context.Policy?has_content]
                [#local policyId = formatDependentPolicyId(subCore.Id)]
                [@createPolicy
                    mode=listMode
                    id=policyId
                    name=_context.Name
                    statements=_context.Policy
                    roles=roleId
                /]
            [/#if]

            [#if linkPolicies?has_content]
                [#local policyId = formatDependentPolicyId(subCore.Id, "links")]
                [@createPolicy
                    mode=listMode
                    id=policyId
                    name="links"
                    statements=linkPolicies
                    roles=roleId
                /]
            [/#if]
        [/#if]
    [/#list]

    [#if deploymentSubsetRequired(USERPOOL_COMPONENT_TYPE, true) ]

        [#if solution.AllowUnauthenticatedUsers && ! unauthenticatedRole?has_content ]
            [@cfException
                mode=listMode
                description="No unauthenicated assignments found"
                context=solution
            /]
        [/#if]

        [#if ! authenticatedRole?has_content && ! ruleAssignments ]
            [@cfException
                mode=listMode
                description="No authenticated assignments found"
                context=solution
            /]
        [/#if]

        [#list federationProviders as id,federationProvider ]
            [#if federationProvider?is_hash ]
                [#if (federationProvider["Rules"]![])?has_content ]

                    [#local providerRules = [] ]
                    [#list federationProvider["Rules"]?sort_by("Priority") as rule  ]
                        [#local providerRules += [ rule.Rule ]]
                    [/#list]

                    [#local ruleAssignments += 
                            getIdentityPoolRoleMapping( 
                                federationProvider["Provider"],
                                subSolution.Type,
                                providerRules,
                                solution.NoMatchBehaviour
                            )]
                [/#if]
            [/#if]
        [/#list]

        [@createIdentityPoolRoleMapping
            mode=listMode
            id=roleMappingId
            identityPoolId=identityPoolId
            roleMappings=ruleAssignments
            authenticatedRoleId=authenticatedRole
            unauthenticatedRoleId=unauthenticatedRole
        /]
    [/#if]
[/#macro]



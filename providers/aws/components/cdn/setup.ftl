[#ftl]
[#macro aws_cdn_cf_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets=["template", "epilogue"] /]
        [#return]
    [/#if]

    [#local core = occurrence.Core ]
    [#local resources = occurrence.State.Resources]
    [#local solution = occurrence.Configuration.Solution ]

    [#local cfId                = resources["cf"].Id]
    [#local cfName              = resources["cf"].Name]

    [#local wafPresent          = isPresent(solution.WAF) ]
    [#local wafAclId            = resources["wafacl"].Id]
    [#local wafAclName          = resources["wafacl"].Name]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(solution.Profiles.Baseline, [ "CDNOriginKey", "OpsData" ])]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]!"") ]
    [#local cfAccess         = getExistingReference(baselineComponentIds["CDNOriginKey"]!"") ]

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

    [#local securityProfile = getSecurityProfile(solution.Profiles.Security, CDN_COMPONENT_TYPE)]

    [#local certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers) ]
    [#local hostName = getHostName(certificateObject, occurrence) ]
    [#local certificateId = formatDomainCertificateId(certificateObject, hostName) ]
    [#local primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
    [#local primaryFQDN = formatDomainName(hostName, primaryDomainObject)]

    [#-- Get alias list --]
    [#local aliases = [] ]
    [#list certificateObject.Domains as domain]
        [#local aliases += [ formatDomainName(hostName, domain.Name) ] ]
    [/#list]

    [#if !cfAccess?has_content]
        [@precondition
            function="solution_spa"
            context=occurrence
            detail="No CF Access Id found"
        /]
        [#return]
    [/#if]

    [#local origins = []]
    [#local cacheBehaviours = []]
    [#local defaultCacheBehaviour = []]

    [#list occurrence.Occurrences![] as subOccurrence]
        [#local subCore = subOccurrence.Core ]
        [#local subSolution = subOccurrence.Configuration.Solution ]
        [#local subResources = subOccurrence.State.Resources ]

        [#local routeBehaviours = []]

        [#local originId = subResources["origin"].Id ]

        [#if !subSolution.Enabled]
            [#continue]
        [/#if]

        [#local contextLinks = getLinkTargets(subOccurrence)]

        [#assign _context =
            {
                "Id" : fragment,
                "Name" : fragment,
                "Instance" : subCore.Instance.Id,
                "Version" : subCore.Version.Id,
                "Environment" : {},
                "Links" : contextLinks,
                "BaselineLinks" : baselineLinks,
                "DefaultEnvironment" : defaultEnvironment(subOccurrence, contextLinks, baselineLinks),
                "DefaultCoreVariables" : false,
                "DefaultEnvironmentVariables" : false,
                "DefaultLinkVariables" : true,
                "DefaultBaselineVariables" : false,
                "Route" : subCore.SubComponent.Id
            }
        ]

        [#-- Add in fragment specifics including override of defaults --]
        [#include fragmentList?ensure_starts_with("/")]

        [#local finalEnvironment = getFinalEnvironment(subOccurrence, _context ) ]
        [#assign _context += finalEnvironment ]

        [#-- Get any event handlers --]
        [#local eventHandlerLinks = {} ]
        [#local eventHandlers = []]

        [#if subSolution.RedirectAliases.Enabled
                    && ( aliases?size > 1) ]

            [#local cfRedirectLink = {
                "cfredirect" : {
                    "Tier" : "gbl",
                    "Component" : "cfredirect",
                    "Version" : subSolution.RedirectAliases.RedirectVersion,
                    "Instance" : "",
                    "Function" : "cfredirect",
                    "Action" : "origin-request"
                }
            }]

            [#if getLinkTarget(occurrence, cfRedirectLink.cfredirect )?has_content ]
                [#local eventHandlerLinks += cfRedirectLink]

                [#assign _context +=
                    {
                        "ForwardHeaders" : (_context.ForwardHeaders![]) + [
                            "Host"
                        ]
                    }]

                [#assign _context +=
                    {
                        "CustomOriginHeaders" : (_context.CustomOriginHeaders![]) + [
                            getCFHTTPHeader(
                                "X-Redirect-Primary-Domain-Name",
                                primaryFQDN ),
                            getCFHTTPHeader(
                                "X-Redirect-Response-Code",
                                "301"
                            )
                        ]
                    }]
            [#else]
                [@fatal
                    message="Could not find cfredirect component"
                    context=cfRedirectLink
                /]
            [/#if]
        [/#if]

        [#local eventHandlerLinks += subSolution.EventHandlers ]
        [#list eventHandlerLinks?values as eventHandler]

            [#local eventHandlerTarget = getLinkTarget(occurrence, eventHandler) ]

            [@debug message="Event message handler" context=eventHandlerTarget enabled=false /]

            [#if !eventHandlerTarget?has_content]
                [#continue]
            [/#if]

            [#local eventHandlerCore = eventHandlerTarget.Core ]
            [#local eventHandlerResources = eventHandlerTarget.State.Resources ]
            [#local eventHandlerAttributes = eventHandlerTarget.State.Attributes ]
            [#local eventHandlerConfiguration = eventHandlerTarget.Configuration ]

            [#if (eventHandlerCore.Type) == LAMBDA_FUNCTION_COMPONENT_TYPE &&
                    eventHandlerAttributes["DEPLOYMENT_TYPE"] == "EDGE" ]

                    [#local eventHandlers += getCFEventHandler(
                                                eventHandler.Action,
                                                eventHandlerResources["version"].Id) ]
            [#else]
                [@fatal
                    description="Invalid Event Handler Component - Must be Lambda - EDGE"
                    context=occurrence
                /]
            [/#if]
        [/#list]

        [#local originLink = getLinkTarget(occurrence, subSolution.Origin.Link) ]

        [#if !originLink?has_content]
            [#continue]
        [/#if]

        [#local originLinkTargetCore = originLink.Core ]
        [#local originLinkTargetConfiguration = originLink.Configuration ]
        [#local originLinkTargetResources = originLink.State.Resources ]
        [#local originLinkTargetAttributes = originLink.State.Attributes ]

        [#switch originLinkTargetCore.Type]

            [#case S3_COMPONENT_TYPE ]

                [#if isPresent(originLinkTargetConfiguration.Solution.Website) ]
                    [#local originBucket = (originLinkTargetAttributes["WEBSITE_URL"])?remove_beginning("http://") ]
                [#else]
                    [#local originBucket = originLinkTargetAttributes["NAME"] ]
                [/#if]

                [#local origin =
                    getCFS3Origin(
                        originId,
                        originBucket,
                        cfAccess,
                        subSolution.Origin.BasePath,
                        _context.CustomOriginHeaders)]
                [#local origins += origin ]

                [#local behaviour = getCFSPACacheBehaviour(
                    origin,
                    subSolution.PathPattern,
                    {
                        "Default" : subSolution.CachingTTL.Default,
                        "Max" : subSolution.CachingTTL.Maximum,
                        "Min" : subSolution.CachingTTL.Minimum
                    },
                    subSolution.Compress,
                    eventHandlers,
                    _context.ForwardHeaders)]
                    [#local routeBehaviours += behaviour ]
                [#break]

            [#case SPA_COMPONENT_TYPE ]

                [#local originBucket = "" ]
                [#local spaOrigin =
                    getCFS3Origin(
                        originId,
                        originBucket,
                        cfAccess,
                        formatAbsolutePath(getSettingsFilePrefix(occurrence), "spa"),
                        _context.CustomOriginHeaders)]
                [#local origins += spaOrigin ]

                [#local configOrigin =
                    getCFS3Origin(
                        formatId(originId, "config"),
                        originBucket,
                        cfAccess,
                        formatAbsolutePath(getSettingsFilePrefix(occurrence)),
                        _context.CustomOriginHeaders)]
                [#local origins += configOrigin ]

                [#local spaCacheBehaviour = getCFSPACacheBehaviour(
                    spaOrigin,
                    subSolution.PathPattern,
                    {
                        "Default" : subSolution.CachingTTL.Default,
                        "Max" : subSolution.CachingTTL.Maximum,
                        "Min" : subSolution.CachingTTL.Minimum
                    },
                    subSolution.Compress,
                    eventHandlers,
                    _context.ForwardHeaders)]
                [#local routeBehaviours += configCacheBehaviour ]

                [#local configCacheBehaviour = getCFSPACacheBehaviour(
                    configOrigin,
                    formatAbsolutePath( subSolution.PathPattern, "config/*"),
                    { "Default" : 60 },
                    subSolution.Compress,
                    eventHandlers,
                    _context.ForwardHeaders) ]

                [#local routeBehaviours += configCacheBehaviour ]
                [#break]

            [#case LB_PORT_COMPONENT_TYPE ]

                [#local origin = 
                            getCFHTTPOrigin(
                                originId,
                                originLinkTargetAttributes["FQDN"],
                                _context.CustomOriginHeaders,
                                formatAbsolutePath( originLinkTargetAttributes["PATH"], subSolution.Origin.BasePath )
                            )]
                [#local origins += origin ]

                [#local behaviour = 
                            getCFLBCacheBehaviour(
                                origin,
                                subSolution.PathPattern,
                                subSolution.CachingTTL,
                                subSolution.Compress,
                                _context.ForwardHeaders,
                                eventHandlers )]
                [#local routeBehaviours += behaviour ]
                [#break]
        [/#switch]

        [#list routeBehaviours as behaviour ]
            [#if (behaviour.PathPattern!"")?has_content ]
                [#local cacheBehaviours += routeBehaviours ]
            [#else]
                [#local defaultCacheBehaviour = behaviour ]
            [/#if]
        [/#list]

        [#if subSolution.InvalidateOnUpdate ]
            [#if deploymentSubsetRequired("epilogue", false)]
                [@addToDefaultBashScriptOutput
                    content=(getExistingReference(cfId)?has_content)?then(
                        [
                            "case $\{STACK_OPERATION} in",
                            "  create|update)"
                        ] +
                        [
                            "# Invalidate distribution",
                            "info \"Invalidating cloudfront distribution ... \"",
                            "invalidate_distribution" +
                            " \"" + region + "\" " +
                            " \"" + getExistingReference(cfId) + "\" || return $?"

                        ] +
                        [
                            "       ;;",
                            "       esac"
                        ],
                        []
                    )
                /]
            [/#if]
        [/#if]
    [/#list]

    [#if deploymentSubsetRequired(CDN_COMPONENT_TYPE, true)]
        [#local restrictions = {} ]
        [#if solution.CountryGroups?has_content]
            [#list asArray(solution.CountryGroups) as countryGroup]
                [#local group = (countryGroups[countryGroup])!{}]
                [#if group.Locations?has_content]
                    [#local restrictions +=
                        getCFGeoRestriction(group.Locations, group.Blacklist!false) ]
                    [#break]
                [/#if]
            [/#list]
        [/#if]

        [@createCFDistribution
            id=cfId
            aliases=
                (isPresent(solution.Certificate))?then(
                    aliases,
                    []
                )
            cacheBehaviours=cacheBehaviours
            certificate=valueIfTrue(
                getCFCertificate(
                    certificateId,
                    securityProfile.HTTPSProfile,
                    solution.AssumeSNI),
                    isPresent(solution.Certificate)
                )
            comment=cfName
            customErrorResponses=
                getErrorResponse(
                        404,
                        200,
                        (solution.Pages.NotFound)?has_content?then(
                            solution.Pages.NotFound,
                            solution.Pages.Error
                        )) +
                getErrorResponse(
                        403,
                        200,
                        (solution.Pages.Denied)?has_content?then(
                            solution.Pages.Denied,
                            solution.Pages.Error
                        ))
            defaultCacheBehaviour=defaultCacheBehaviour
            defaultRootObject=solution.Pages.Root
            logging=valueIfTrue(
                getCFLogging(
                    operationsBucket,
                    formatComponentAbsoluteFullPath(
                        core.Tier,
                        core.Component,
                        occurrence
                    )
                ),
                solution.EnableLogging)
            origins=origins
            restrictions=valueIfContent(
                restrictions,
                restrictions)
            wafAclId=valueIfTrue(wafAclId, wafPresent)
        /]

        [#if wafPresent ]
            [@createWAFAclFromSecurityProfile
                id=wafAclId
                name=wafAclName
                metric=wafAclName
                wafSolution=solution.WAF
                securityProfile=securityProfile
                occurrence=occurrence /]
        [/#if]
    [/#if]

[/#macro]

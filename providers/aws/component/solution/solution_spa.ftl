[#ftl]
[#macro aws_spa_cf_solution occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template", "epilogue"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core ]
    [#local resources = occurrence.State.Resources]
    [#local solution = occurrence.Configuration.Solution ]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local contextLinks = getLinkTargets(occurrence) ]
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
            "CustomOriginHeaders" : [],
            "ForwardHeaders" : []
        }
    ]

    [#-- Add in container specifics including override of defaults --]
    [#local fragmentListMode = "model"]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local securityProfile    = getSecurityProfile(solution.Profiles.Security, SPA_COMPONENT_TYPE)]

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

    [#-- Get any event handlers --]
    [#local eventHandlerLinks = {} ]
    [#local eventHandlers = []]

    [#if solution.CloudFront.RedirectAliases.Enabled
                && ( aliases?size > 1) ]

        [#local cfRedirectLink = {
            "cfredirect" : {
                "Tier" : "gbl",
                "Component" : "cfredirect",
                "Version" : solution.CloudFront.RedirectAliases.RedirectVersion,
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
            [@cfException
                mode=listMode
                description="Could not find cfredirect component"
                context=cfRedirectLink
            /]
        [/#if]
    [/#if]

    [#local eventHandlerLinks += solution.CloudFront.EventHandlers ]
    [#list eventHandlerLinks?values as eventHandler]

        [#local eventHandlerTarget = getLinkTarget(occurrence, eventHandler) ]

        [@cfDebug listMode eventHandlerTarget false /]

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
            [@cfException
                    mode=listMode
                    description="Invalid Event Handler Component - Must be Lambda - EDGE"
                    context=occurrence
                /]
        [/#if]
    [/#list]

    [#local cfId               = resources["cf"].Id]
    [#local cfName             = resources["cf"].Name]
    [#local cfSPAOriginId      = resources["cforiginspa"].Id]
    [#local cfConfigOriginId   = resources["cforiginconfig"].Id]

    [#local bucketId = formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, "opsdata" ) ]
    [#if !getExistingReference(bucketId)?has_content ]
        [#local bucketId = formatS3OperationsId() ]
    [/#if]

    [#local cfAccess = getExistingReference(formatDependentCFAccessId(bucketId)) ]

    [#if !cfAccess?has_content]
        [@cfPreconditionFailed listMode "solution_spa" occurrence "No CF Access Id found" /]
        [#return]
    [/#if]

    [#local wafPresent     = isPresent(solution.WAF) ]
    [#local wafAclId       = resources["wafacl"].Id]
    [#local wafAclName     = resources["wafacl"].Name]

    [#if deploymentSubsetRequired("spa", true)]
        [#local origins = []]
        [#local cacheBehaviours = []]

        [#local spaOrigin =
            getCFS3Origin(
                cfSPAOriginId,
                operationsBucket,
                cfAccess,
                formatAbsolutePath(getSettingsFilePrefix(occurrence), "spa"),
                _context.CustomOriginHeaders)]
        [#local origins += spaOrigin ]

        [#local configOrigin =
            getCFS3Origin(
                cfConfigOriginId,
                operationsBucket,
                cfAccess,
                formatAbsolutePath(getSettingsFilePrefix(occurrence)),
                _context.CustomOriginHeaders)]
        [#local origins += configOrigin ]

        [#local spaCacheBehaviour = getCFSPACacheBehaviour(
            spaOrigin,
            "",
            {
                "Default" : solution.CloudFront.CachingTTL.Default,
                "Max" : solution.CloudFront.CachingTTL.Maximum,
                "Min" : solution.CloudFront.CachingTTL.Minimum
            },
            solution.CloudFront.Compress,
            eventHandlers,
            _context.ForwardHeaders)]

        [#local configCacheBehaviour = getCFSPACacheBehaviour(
            configOrigin,
            "/config/*",
            {"Default" : 60},
            solution.CloudFront.Compress,
            eventHandlers,
            _context.ForwardHeaders) ]
        [#local cacheBehaviours += configCacheBehaviour ]

        [#list resources["paths"]!{} as id, path ]
            [#local pathOriginIdId = path["cforigin"]["Id"] ]
            [#local pathSolution = solution.CloudFront.Paths[id] ]

            [#local pathLink = getLinkTarget(occurrence, pathSolution.Link) ]

            [#if !pathLink?has_content]
                [#continue]
            [/#if]

            [#local pathLinkTargetCore = pathLink.Core ]
            [#local pathLinkTargetConfiguration = pathLink.Configuration ]
            [#local pathLinkTargetResources = pathLink.State.Resources ]
            [#local pathLinkTargetAttributes = pathLink.State.Attributes ]

            [#switch pathLinkTargetCore.Type]
                [#case LB_PORT_COMPONENT_TYPE ]
                    [#local pathOrigin = getCFHTTPOrigin(
                                                pathOriginIdId,
                                                pathLinkTargetAttributes["FQDN"],
                                                _context.CustomOriginHeaders,
                                                pathLinkTargetAttributes["PATH"]
                    )]
                    [#local origins += pathOrigin ]
                    [#break]
            [/#switch]

            [#local pathBehaviour = getCFLBCacheBehaviour(
                                        pathOrigin,
                                        pathSolution.PathPattern,
                                        pathSolution.CachingTTL,
                                        pathSolution.Compress,
                                        _context.ForwardHeaders,
                                        eventHandlers

            )]
            [#local cacheBehaviours += pathBehaviour ]
        [/#list]

        [#local restrictions = {} ]
        [#if solution.CloudFront.CountryGroups?has_content]
            [#list asArray(solution.CloudFront.CountryGroups) as countryGroup]
                [#local group = (countryGroups[countryGroup])!{}]
                [#if group.Locations?has_content]
                    [#local restrictions +=
                        getCFGeoRestriction(group.Locations, group.Blacklist!false) ]
                    [#break]
                [/#if]
            [/#list]
        [/#if]

        [@createCFDistribution
            mode=listMode
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
                    solution.CloudFront.AssumeSNI),
                    isPresent(solution.Certificate)
                )
            comment=cfName
            customErrorResponses=getErrorResponse(
                                        404,
                                        200,
                                        (solution.CloudFront.NotFoundPage)?has_content?then(
                                            solution.CloudFront.NotFoundPage,
                                            solution.CloudFront.ErrorPage
                                        )) +
                                getErrorResponse(
                                        403,
                                        200,
                                        (solution.CloudFront.DeniedPage)?has_content?then(
                                            solution.CloudFront.DeniedPage,
                                            solution.CloudFront.ErrorPage
                                        ))
            defaultCacheBehaviour=spaCacheBehaviour
            defaultRootObject="index.html"
            logging=valueIfTrue(
                getCFLogging(
                    operationsBucket,
                    formatComponentAbsoluteFullPath(
                        core.Tier,
                        core.Component,
                        occurrence
                    )
                ),
                solution.CloudFront.EnableLogging)
            origins=origins
            restrictions=valueIfContent(
                restrictions,
                restrictions)
            wafAclId=valueIfTrue(wafAclId, wafPresent)
        /]

        [#if wafPresent ]
            [@createWAFAclFromSecurityProfile
                mode=listMode
                id=wafAclId
                name=wafAclName
                metric=wafAclName
                wafSolution=solution.WAF
                securityProfile=securityProfile
                occurrence=occurrence /]
        [/#if]
    [/#if]
    [#if deploymentSubsetRequired("epilogue", false)]
        [@cfScript
            mode=listMode
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
[/#macro]

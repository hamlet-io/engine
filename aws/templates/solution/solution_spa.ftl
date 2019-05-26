[#ftl]
[#macro solution_spa tier component]
    [#-- Single Page App --]
    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign resources = occurrence.State.Resources]
        [#assign solution = occurrence.Configuration.Solution ]

        [#assign fragment =
            contentIfContent(solution.Fragment, getComponentId(component)) ]

        [#assign contextLinks = getLinkTargets(occurrence) ]
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
        [#assign fragmentListMode = "model"]
        [#assign fragmentId = formatFragmentId(_context)]
        [#include fragmentList?ensure_starts_with("/")]

        [#assign securityProfile    = getSecurityProfile(solution.Profiles.Security, SPA_COMPONENT_TYPE)]

        [#assign certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers) ]
        [#assign hostName = getHostName(certificateObject, occurrence) ]
        [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]
        [#assign primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
        [#assign primaryFQDN = formatDomainName(hostName, primaryDomainObject)]

        [#-- Get alias list --]
        [#assign aliases = [] ]
        [#list certificateObject.Domains as domain]
            [#assign aliases += [ formatDomainName(hostName, domain.Name) ] ]
        [/#list]

        [#-- Get any event handlers --]
        [#assign eventHandlerLinks = {} ]
        [#assign eventHandlers = []]

        [#if solution.CloudFront.RedirectAliases.Enabled
                    && ( aliases?size > 1) ]

            [#assign cfRedirectLink = {
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
                [#assign eventHandlerLinks += cfRedirectLink]

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

        [#assign eventHandlerLinks += solution.CloudFront.EventHandlers ]
        [#list eventHandlerLinks?values as eventHandler]

            [#assign eventHandlerTarget = getLinkTarget(occurrence, eventHandler) ]

            [@cfDebug listMode eventHandlerTarget false /]

            [#if !eventHandlerTarget?has_content]
                [#continue]
            [/#if]

            [#assign eventHandlerCore = eventHandlerTarget.Core ]
            [#assign eventHandlerResources = eventHandlerTarget.State.Resources ]
            [#assign eventHandlerAttributes = eventHandlerTarget.State.Attributes ]
            [#assign eventHandlerConfiguration = eventHandlerTarget.Configuration ]

            [#if (eventHandlerCore.Type) == LAMBDA_FUNCTION_COMPONENT_TYPE &&
                    eventHandlerAttributes["DEPLOYMENT_TYPE"] == "EDGE" ]

                    [#assign eventHandlers += getCFEventHandler(
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

        [#assign cfId               = resources["cf"].Id]
        [#assign cfName             = resources["cf"].Name]
        [#assign cfSPAOriginId      = resources["cforiginspa"].Id]
        [#assign cfConfigOriginId   = resources["cforiginconfig"].Id]

        [#assign bucketId = formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, "opsdata" ) ]
        [#if !getExistingReference(bucketId)?has_content ]
            [#assign bucketId = formatS3OperationsId() ]
        [/#if]

        [#assign cfAccess = getExistingReference(formatDependentCFAccessId(bucketId)) ]

        [#if !cfAccess?has_content]
            [@cfPreconditionFailed listMode "solution_spa" occurrence "No CF Access Id found" /]
            [#break]
        [/#if]


        [#assign wafPresent     = isPresent(solution.WAF) ]
        [#assign wafAclId       = resources["wafacl"].Id]
        [#assign wafAclName     = resources["wafacl"].Name]

        [#if deploymentSubsetRequired("spa", true)]
            [#assign origins = []]
            [#assign cacheBehaviours = []]

            [#assign spaOrigin =
                getCFS3Origin(
                    cfSPAOriginId,
                    operationsBucket,
                    cfAccess,
                    formatAbsolutePath(getSettingsFilePrefix(occurrence), "spa"),
                    _context.CustomOriginHeaders)]
            [#assign origins += spaOrigin ]

            [#assign configOrigin =
                getCFS3Origin(
                    cfConfigOriginId,
                    operationsBucket,
                    cfAccess,
                    formatAbsolutePath(getSettingsFilePrefix(occurrence)),
                    _context.CustomOriginHeaders)]
            [#assign origins += configOrigin ]

            [#assign spaCacheBehaviour = getCFSPACacheBehaviour(
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

            [#assign configCacheBehaviour = getCFSPACacheBehaviour(
                configOrigin,
                "/config/*",
                {"Default" : 60},
                solution.CloudFront.Compress,
                eventHandlers,
                _context.ForwardHeaders) ]
            [#assign cacheBehaviours += configCacheBehaviour ]

            [#list resources["paths"]!{} as id, path ]
                [#assign pathOriginIdId = path["cforigin"]["Id"] ]
                [#assign pathSolution = solution.CloudFront.Paths[id] ]

                [#assign pathLink = getLinkTarget(occurrence, pathSolution.Link) ]

                [#if !pathLink?has_content]
                    [#continue]
                [/#if]

                [#assign pathLinkTargetCore = pathLink.Core ]
                [#assign pathLinkTargetConfiguration = pathLink.Configuration ]
                [#assign pathLinkTargetResources = pathLink.State.Resources ]
                [#assign pathLinkTargetAttributes = pathLink.State.Attributes ]

                [#switch pathLinkTargetCore.Type]
                    [#case LB_PORT_COMPONENT_TYPE ]
                        [#assign pathOrigin = getCFHTTPOrigin(
                                                    pathOriginIdId,
                                                    pathLinkTargetAttributes["FQDN"],
                                                    _context.CustomOriginHeaders,
                                                    pathLinkTargetAttributes["PATH"]
                        )]
                        [#assign origins += pathOrigin ]
                        [#break]
                [/#switch]

                [#assign pathBehaviour = getCFLBCacheBehaviour(
                                            pathOrigin,
                                            pathSolution.PathPattern,
                                            pathSolution.CachingTTL,
                                            pathSolution.Compress,
                                            _context.ForwardHeaders,
                                            eventHandlers

                )]
                [#assign cacheBehaviours += pathBehaviour ]
            [/#list]

            [#assign restrictions = {} ]
            [#if solution.CloudFront.CountryGroups?has_content]
                [#list asArray(solution.CloudFront.CountryGroups) as countryGroup]
                    [#assign group = (countryGroups[countryGroup])!{}]
                    [#if group.Locations?has_content]
                        [#assign restrictions +=
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
                            tier,
                            component,
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
    [/#list]
[/#macro]

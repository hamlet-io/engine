[#-- SPA --]

[#if componentType == SPA_COMPONENT_TYPE]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign settings = occurrence.Configuration.Settings ]
        [#assign resources = occurrence.State.Resources]

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
                "DefaultLinkVariables" : false
            }
        ]

        [#-- Add in container specifics including override of defaults --]
        [#assign fragmentListMode = "model"]
        [#assign fragmentId = formatFragmentId(_context)]
        [#assign containerId = fragmentId]
        [#include fragmentList?ensure_starts_with("/")]

        [#assign _context += getFinalEnvironment(occurrence, _context) ]

        [#if deploymentSubsetRequired("config", false)]
            [@cfConfig
                mode=listMode
                content=_context.Environment
            /]
        [/#if]
        [#if deploymentSubsetRequired("prologue", false)]

            [@cfScript
                mode=listMode
                content=
                    getBuildScript(
                        "spaFiles",
                        regionId,
                        "spa",
                        productName,
                        occurrence,
                        "spa.zip"
                    ) +
                    syncFilesToBucketScript(
                        "spaFiles",
                        regionId,
                        operationsBucket,
                        formatRelativePath(
                            getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                            "spa"
                        )
                    ) +
                    getLocalFileScript(
                        "configFiles",
                        "$\{CONFIG}",
                        "config.json"
                    ) +
                    syncFilesToBucketScript(
                        "configFiles",
                        regionId,
                        operationsBucket,
                        formatRelativePath(
                            getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                            "config"
                        )
                    ) /]

            [#assign cfId = resources["cf"].Id]

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

        [#assign securityProfile    = getSecurityProfile(solution.Profiles.Security, SPA_COMPONENT_TYPE)]

        [#assign certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers) ]
        [#assign hostName = getHostName(certificateObject, occurrence) ]
        [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

        [#-- Get alias list --]
        [#assign aliases = [] ]
        [#list certificateObject.Domains as domain]
            [#assign aliases += [ formatDomainName(hostName, domain.Name) ] ]
        [/#list]

        [#-- Get any event handlers --]
        [#assign eventHandlers = [] ]
        [#assign originRequestHandler =
          getOccurrenceSettingValue(occurrence, ["EventHandlers", "OriginRequest"], true) ]
        [#if originRequestHandler?has_content]
            [#assign eventHandlers += getCFEventHandler("origin-request", originRequestHandler) ]
        [/#if]

        [#assign cfId               = resources["cf"].Id]
        [#assign cfName             = resources["cf"].Name]
        [#assign cfSPAOriginId      = resources["cforiginspa"].Id]
        [#assign cfConfigOriginId   = resources["cforiginconfig"].Id]
        [#assign cfUtilities        = resources["cfUtilities"]]

        [#if ! (getExistingReference(formatDependentCFAccessId(formatS3OperationsId()))?has_content)]
            [@cfPreconditionFailed listMode "solution_spa" occurrence "No CF Access Id found" /]
            [#break]
        [/#if]

        [#assign cfAccess = getExistingReference(formatDependentCFAccessId(formatS3OperationsId()))]

        [#assign wafPresent     = isPresent(solution.WAF) ]
        [#assign wafAclId       = resources["wafacl"].Id]
        [#assign wafAclName     = resources["wafacl"].Name]

        [#if deploymentSubsetRequired("cdn", true) && isPartOfCurrentDeploymentUnit(cfId)]

            [#assign spaOrigin =
                getCFS3Origin(
                    cfSPAOriginId,
                    operationsBucket,
                    cfAccess,
                    formatAbsolutePath(getSettingsFilePrefix(occurrence), "spa"))]
            [#assign configOrigin =
                getCFS3Origin(
                    cfConfigOriginId,
                    operationsBucket,
                    cfAccess,
                    formatAbsolutePath(getSettingsFilePrefix(occurrence)))]

            [#assign spaCacheBehaviour = getCFSPACacheBehaviour(
                spaOrigin,
                "",
                {
                    "Default" : solution.CloudFront.CachingTTL.Default,
                    "Max" : solution.CloudFront.CachingTTL.Maximum,
                    "Min" : solution.CloudFront.CachingTTL.Minimum
                },
                solution.CloudFront.Compress,
                eventHandlers)]
            [#assign configCacheBehaviour = getCFSPACacheBehaviour(
                configOrigin,
                "/config/*",
                {"Default" : 60},
                solution.CloudFront.Compress,
                eventHandlers) ]

            [#assign restrictions = {} ]
            [#list solution.CloudFront.CountryGroups as countryGroup]
                [#assign group = (countryGroups[countryGroup])!{}]
                [#if group.Locations?has_content]
                    [#assign restrictions +=
                        getCFGeoRestriction(group.Locations, group.Blacklist!false) ]
                    [#break]
                [/#if]
            [/#list]

            [@createCFDistribution
                mode=listMode
                id=cfId
                aliases=
                    (isPresent(solution.Certificate))?then(
                        aliases,
                        []
                    )
                cacheBehaviours=configCacheBehaviour
                certificate=valueIfTrue(
                    getCFCertificate(
                        certificateId,
                        securityProfile.HTTPSProfile,
                        solution.CloudFront.AssumeSNI),
                        isPresent(solution.Certificate)
                    )
                comment=cfName
                customErrorResponses=
                    getErrorResponse(
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
                        core.FullAbsolutePath
                        )
                    ),
                    solution.CloudFront.EnableLogging)
                origins=spaOrigin + configOrigin
                restrictions=restrictions
                wafAclId=valueIfTrue(wafAclId, wafPresent)
            /]

            [#if wafPresent ]
                [@createWAFAcl
                    mode=listMode
                    id=wafAclId
                    name=wafAclName
                    metric=wafAclName
                    default=getWAFDefault(solution.WAF)
                    rules=getWAFRules(solution.WAF) /]
            [/#if]
        [/#if]
    [/#list]
[/#if]

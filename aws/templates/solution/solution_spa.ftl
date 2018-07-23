[#-- Single Page App --]

[#if componentType == SPA_COMPONENT_TYPE]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign resources = occurrence.State.Resources]
        [#assign solution = occurrence.Configuration.Solution ]

        [#assign certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers) ]
        [#assign hostName = getHostName(certificateObject, occurrence) ]
        [#assign dns = formatDomainName(hostName, certificateObject.Domain.Name) ]
        [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

        [#assign cfId               = resources["cf"].Id]
        [#assign cfName             = resources["cf"].Name]
        [#assign cfSPAOriginId      = resources["cforiginspa"].Id]
        [#assign cfConfigOriginId   = resources["cforiginconfig"].Id]

        [#if ! (getExistingReference(formatDependentCFAccessId(formatS3OperationsId()))?has_content)]
            [@cfPreconditionFailed listMode "solution_spa" occurrence "No CF Access Id found" /]
            [#break]
        [/#if]

        [#assign cfAccess = getExistingReference(formatDependentCFAccessId(formatS3OperationsId()))]

        [#assign wafPresent     = isWAFPresent(solution.WAF) ]
        [#assign wafAclId       = resources["wafacl"].Id]
        [#assign wafAclName     = resources["wafacl"].Name]

        [#if deploymentSubsetRequired("spa", true)]
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
                solution.CloudFront.Compress)]
            [#assign configCacheBehaviour = getCFSPACacheBehaviour(
                configOrigin,
                "/config/*",
                {"Default" : 60},
                solution.CloudFront.Compress) ]

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
                    (solution.Certificate.Configured && solution.Certificate.Enabled)?then(
                        [dns],
                        []
                    )
                cacheBehaviours=configCacheBehaviour
                certificate=valueIfTrue(
                    getCFCertificate(
                        certificateId,
                        solution.CloudFront.AssumeSNI),
                        solution.Certificate.Configured && solution.Certificate.Enabled)
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
                origins=spaOrigin + configOrigin
                restrictions=valueIfContent(
                    restrictions,
                    restrictions)
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
[/#if]

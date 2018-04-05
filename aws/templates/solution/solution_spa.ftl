[#-- Single Page App --]

[#if (componentType == SPA_COMPONENT_TYPE) && deploymentSubsetRequired("spa", true)]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]
        [#assign resources = occurrence.State.Resources]

        [#assign certificateObject = getCertificateObject(configuration.Certificate, segmentId, segmentName) ]
        [#assign hostName = getHostName(certificateObject, tier, component, occurrence) ]
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

        [#assign wafAclId       = resources["wafacl"].Id]
        [#assign wafAclName     = resources["wafacl"].Name]

        [#assign spaOrigin =       
            getCFS3Origin(
                cfSPAOriginId,
                operationsBucket,
                cfAccess,
                formatAbsolutePath(getAppSettingsFilePrefix(), "spa"))]
        [#assign configOrigin =       
            getCFS3Origin(
                cfConfigOriginId,
                operationsBucket,
                cfAccess,
                formatAbsolutePath(getAppSettingsFilePrefix()))]

        [#assign spaCacheBehaviour = getCFSPACacheBehaviour(
            spaOrigin, 
            "", 
            {
                "Default" : configuration.CloudFront.CachingTTL.Default,
                "Max" : configuration.CloudFront.CachingTTL.Maximum,
                "Min" : configuration.CloudFront.CachingTTL.Minimum
            })]
        [#assign configCacheBehaviour = getCFSPACacheBehaviour(configOrigin, "/config/*", {"Default" : 60}) ]

        [#assign restrictions = {} ]
        [#if configuration.CloudFront.CountryGroups?has_content]
            [#list asArray(configuration.CloudFront.CountryGroups) as countryGroup]
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
                (configuration.Certificate.Configured && configuration.Certificate.Enabled)?then(
                    [dns],
                    []
                )
            cacheBehaviours=configCacheBehaviour
            certificate=valueIfTrue(
                getCFCertificate(
                    certificateId,
                    configuration.CloudFront.AssumeSNI),
                    configuration.Certificate.Configured && configuration.Certificate.Enabled)
            comment=cfName
            customErrorResponses=getErrorResponse(
                                        404, 
                                        200,
                                        (configuration.CloudFront.NotFoundPage)?has_content?then(
                                            configuration.CloudFront.NotFoundPage,
                                            configuration.CloudFront.ErrorPage
                                        )) + 
                                getErrorResponse(
                                        403, 
                                        200,
                                        (configuration.CloudFront.DeniedPage)?has_content?then(
                                            configuration.CloudFront.DeniedPage,
                                            configuration.CloudFront.ErrorPage
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
                configuration.CloudFront.EnableLogging)
            origins=spaOrigin + configOrigin
            restrictions=valueIfContent(
                restrictions,
                restrictions)
            wafAclId=valueIfTrue(
                wafAclId,
                (configuration.WAF.Configured &&
                    configuration.WAF.Enabled &&
                    ipAddressGroupsUsage["waf"]?has_content))
        /]

        [#if configuration.WAF.Configured &&
                configuration.WAF.Enabled &&
                ipAddressGroupsUsage["waf"]?has_content ]
            [#assign wafGroups = [] ]
            [#assign wafRuleDefault = 
                        configuration.WAF.RuleDefault?has_content?then(
                            configuration.WAF.RuleDefault,
                            "ALLOW")]
            [#assign wafDefault = 
                        configuration.WAF.Default?has_content?then(
                            configuration.WAF.Default,
                            "BLOCK")]
            [#if configuration.WAF.IPAddressGroups?has_content]
                [#list configuration.WAF.IPAddressGroups as group]
                    [#assign groupId = group?is_hash?then(
                                    group.Id,
                                    group)]
                    [#if (ipAddressGroupsUsage["waf"][groupId])?has_content]
                        [#assign usageGroup = ipAddressGroupsUsage["waf"][groupId]]
                        [#if usageGroup.IsOpen]
                            [#assign wafRuleDefault = 
                                configuration.WAF.RuleDefault?has_content?then(
                                    configuration.WAF.RuleDefault,
                                    "COUNT")]
                            [#assign wafDefault = 
                                    configuration.WAF.Default?has_content?then(
                                        configuration.WAF.Default,
                                        "ALLOW")]
                        [/#if]
                        [#if usageGroup.CIDR?has_content]
                            [#assign wafGroups += 
                                        group?is_hash?then(
                                            [group],
                                            [{"Id" : groupId}]
                                        )]
                        [/#if]
                    [/#if]
                [/#list]
            [#else]
                [#list ipAddressGroupsUsage["waf"]?values as usageGroup]
                    [#if usageGroup.IsOpen]
                        [#assign wafRuleDefault = 
                            configuration.WAF.RuleDefault?has_content?then(
                                configuration.WAF.RuleDefault,
                                "COUNT")]
                        [#assign wafDefault = 
                                configuration.WAF.Default?has_content?then(
                                    configuration.WAF.Default,
                                    "ALLOW")]
                    [/#if]
                    [#if usageGroup.CIDR?has_content]
                        [#assign wafGroups += [{"Id" : usageGroup.Id}]]
                    [/#if]
                [/#list]
            [/#if]

            [#assign wafRules = []]
            [#list wafGroups as group]
                [#assign wafRules += [
                        {
                            "Id" : "${formatWAFIPSetRuleId(group)}",
                            "Action" : "${(group.Action?upper_case)!wafRuleDefault}"
                        }
                    ]
                ]
            [/#list]
            [@createWAFAcl 
                mode=listMode
                id=wafAclId
                name=wafAclName
                metric=wafAclName
                default=wafDefault
                rules=wafRules /]
        [/#if]
    [/#list]
[/#if]

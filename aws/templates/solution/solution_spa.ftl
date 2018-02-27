[#-- Single Page App --]

[#if (componentType == "spa") && deploymentSubsetRequired("spa", true)]
    [#assign spa = component.SPA]

    [#list requiredOccurrences(
            getOccurrences(component, tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]

        [#assign certificateObject = getCertificateObject(configuration.Certificate, segmentId, segmentName) ]
        [#assign hostName = getHostName(certificateObject, tier, component, occurrence) ]
        [#assign dns = formatDomainName(hostName, certificateObject.Domain.Name) ]
        [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]
  
        [#assign cfId  = formatComponentCFDistributionId(
                                tier,
                                component,
                                occurrence)]
                                
        [#assign cfName  = formatComponentCFDistributionName(
                                tier,
                                component,
                                occurrence)]

        [#assign cfAccess =
            getExistingReference(formatDependentCFAccessId(formatS3OperationsId()))]
        [#assign cfAccess = valueIfContent(cfAccess, cfAccess, "ERROR_CLOUDFRONT_ACCESS_IDENTITY_NOT_FOUND")]
        
        [#assign wafAclId  = formatDependentWAFAclId(cfId)]

        [#assign wafAclName  = formatComponentWAFAclName(
                                tier,
                                component,
                                occurrence)]

        [#assign spaOrigin =       
            getCFS3Origin(
                "spa",
                operationsBucket,
                cfAccess,
                formatAbsolutePath(getAppSettingsFilePrefix(), "spa"))]
        [#assign configOrigin =       
            getCFS3Origin(
                "config",
                operationsBucket,
                cfAccess,
                formatAbsolutePath(getAppSettingsFilePrefix()))]

        [#assign spaCacheBehaviour = getCFSPACacheBehaviour(spaOrigin) ]
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
                                        configuration.CloudFront.ErrorPage) + 
                                getErrorResponse(
                                        403, 
                                        200,
                                        configuration.CloudFront.ErrorPage)
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

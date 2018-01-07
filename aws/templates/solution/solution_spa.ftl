[#-- Single Page App --]

[#if (componentType == "spa") && deploymentSubsetRequired("spa", true)]
    [#assign spa = component.SPA]

    [#list getOccurrences(component, deploymentUnit) as occurrence]

        [#assign certificateObject = getCertificateObject(occurrence.Certificate, segmentId, segmentName) ]
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
        [#if occurrence.CloudFront.CountryGroups?has_content]
            [#list asArray(occurrence.CloudFront.CountryGroups) as countryGroup]
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
                (occurrence.CertificateIsConfigured && occurrence.Certificate.Enabled)?then(
                    [dns],
                    []
                )
            cacheBehaviours=configCacheBehaviour
            certificate=valueIfTrue(
                getCFCertificate(
                    certificateId,
                    occurrence.CloudFront.AssumeSNI),
                    occurrence.CertificateIsConfigured && occurrence.Certificate.Enabled)
            comment=cfName
            customErrorResponses=getErrorResponse(404) + getErrorResponse(403)
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
                occurrence.CloudFront.EnableLogging)
            origins=spaOrigin + configOrigin
            restrictions=valueIfContent(
                restrictions,
                restrictions)
            wafAclId=valueIfTrue(
                wafAclId,
                (occurrence.WAFIsConfigured &&
                    ipAddressGroupsUsage["waf"]?has_content))
        /]

        [#if occurrence.WAFIsConfigured &&
                ipAddressGroupsUsage["waf"]?has_content ]
            [#assign wafGroups = [] ]
            [#assign wafRuleDefault = 
                        occurrence.WAF.RuleDefault?has_content?then(
                            occurrence.WAF.RuleDefault,
                            "ALLOW")]
            [#assign wafDefault = 
                        occurrence.WAF.Default?has_content?then(
                            occurrence.WAF.Default,
                            "BLOCK")]
            [#if occurrence.WAF.IPAddressGroups?has_content]
                [#list occurrence.WAF.IPAddressGroups as group]
                    [#assign groupId = group?is_hash?then(
                                    group.Id,
                                    group)]
                    [#if (ipAddressGroupsUsage["waf"][groupId])?has_content]
                        [#assign usageGroup = ipAddressGroupsUsage["waf"][groupId]]
                        [#if usageGroup.IsOpen]
                            [#assign wafRuleDefault = 
                                occurrence.WAF.RuleDefault?has_content?then(
                                    occurrence.WAF.RuleDefault,
                                    "COUNT")]
                            [#assign wafDefault = 
                                    occurrence.WAF.Default?has_content?then(
                                        occurrence.WAF.Default,
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
                            occurrence.WAF.RuleDefault?has_content?then(
                                occurrence.WAF.RuleDefault,
                                "COUNT")]
                        [#assign wafDefault = 
                                occurrence.WAF.Default?has_content?then(
                                    occurrence.WAF.Default,
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

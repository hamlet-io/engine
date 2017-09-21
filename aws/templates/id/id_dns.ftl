[#-- DNS --]

[#-- Names --]
[#function formatHostDomainName host parts style=""]
    [#local result =
        formatDomainName(
            formatName(host),
            parts
        )]
    [#switch style]
        [#case "hyphenated"]
            [#return result?replace(".", "-")]
            [#break]
        [#default]
            [#return result]
    [/#switch]

[/#function]

[#-- Resources --]

[#function formatDomainId ids...]
    [#return formatResourceId(
                "domain",
                ids)]
[/#function]

[#function formatDependentDomainId resourceId extensions...]
    [#return formatDependentResourceId(
                "domain",
                resourceId,
                extensions)]
[/#function]

[#function formatSegmentDomainId extensions...]
    [#return 
        migrateToResourceId(
            formatSegmentResourceId(
                "domain",
                extensions),
            formatSegmentResourceId(
                "domain",
                "domain",
                extensions)
        )]
[/#function]

[#function formatComponentDomainId tier component extensions...]
    [#return formatComponentResourceId(
                "domain",
                tier,
                component,
                extensions)]
[/#function]

[#function formatAccountDomainId extensions...]
    [#return 
        migrateToResourceId(
            formatAccountResourceId(
                "domain",
                extensions),
            formatAccountResourceId(
                "domain",
                "domain",
                extensions)
        )]
[/#function]

[#function formatSegmentDNSZoneId extensions...]
    [#return formatSegmentResourceId(
                "dnszone",
                extensions)]
[/#function]

[#-- Attributes --]

[#function formatDomainQualifierId ids...]
    [#return formatQualifierAttributeId(
                formatDomainId(ids))]
[/#function]

[#function formatDomainCertificateId ids...]
    [#return formatCertificateAttributeId(
                formatDomainId(ids))]
[/#function]

[#function formatDependentDomainQualifierId resourceId extensions...]
    [#return formatQualifierAttributeId(
                formatDependentDomainId(
                    resourceId,
                    extensions))]
[/#function]

[#function formatDependentDomainCertificateId resourceId extensions...]
    [#return formatCertificateAttributeId(
                formatDependentDomainId(
                    resourceId,
                    extensions))]
[/#function]

[#function formatSegmentDomainQualifierId extensions...]
    [#return 
        migrateToResourceId(
            formatQualifierAttributeId(formatSegmentDomainId(extensions)),
            formatQualifierAttributeId(
                formatSegmentResourceId(
                    "domain",
                    extensions))
        )]
[/#function]

[#function formatSegmentDomainCertificateId extensions...]
    [#return 
        migrateToResourceId(
            formatCertificateAttributeId(formatSegmentDomainId(extensions)),
            formatCertificateAttributeId(
                formatSegmentResourceId(
                    "domain",
                            extensions))
        )]
[/#function]

[#function formatComponentDomainQualifierId tier component extensions...]
    [#return formatQualifierAttributeId(
                formatComponentDomainId(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatComponentDomainCertificateId tier component extensions...]
    [#return formatCertificateAttributeId(
                formatComponentDomainId(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatAccountDomainQualifierId extensions...]
    [#return formatQualifierAttributeId(
                formatAccountResourceId(
                    "domain",
                    extensions))]
[/#function]

[#function formatAccountDomainCertificateId extensions...]
    [#return formatCertificateAttributeId(
                formatAccountResourceId(
                    "domain",
                    extensions))]
[/#function]

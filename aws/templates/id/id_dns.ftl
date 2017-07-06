[#-- DNS --]

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
    [#local legacyId = formatSegmentResourceId(
                "domain",
                "domain",
                extensions)]
    [#return getKey(legacyId)?has_content?then(
                legacyId,
                formatSegmentResourceId(
                    "domain",
                    extensions))]
[/#function]

[#function formatComponentDomainId tier component extensions...]
    [#return formatComponentResourceId(
                "domain",
                tier,
                component,
                extensions)]
[/#function]

[#function formatAccountDomainId extensions...]
    [#local legacyId = formatAccountResourceId(
                "domain",
                "domain",
                extensions)]
    [#return getKey(legacyId)?has_content?then(
                legacyId,
                formatAccountResourceId(
                    "domain",
                    extensions))]
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
    [#local legacyId = formatQualifierAttributeId(
                            formatSegmentResourceId(
                                "domain",
                                extensions))]
    [#return getKey(legacyId)?has_content?then(
                legacyId,
                formatQualifierAttributeId(
                    formatSegmentDomainId(extensions)))]
[/#function]

[#function formatSegmentDomainCertificateId extensions...]
    [#local legacyId = formatCertificateAttributeId(
                            formatSegmentResourceId(
                                "domain",
                                extensions))]
    [#return getKey(legacyId)?has_content?then(
                legacyId,
                formatCertificateAttributeId(
                    formatSegmentDomainId(extensions)))]
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

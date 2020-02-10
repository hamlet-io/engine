[#ftl]

[#-- Resources --]
[#function formatDomainId ids...]
    [#return formatResourceId(
                "domain",
                ids)]
[/#function]

[#function formatSegmentDNSZoneId extensions...]
    [#return formatSegmentResourceId(
                "dnszone",
                extensions)]
[/#function]


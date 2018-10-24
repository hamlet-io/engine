[#-- DNS --]

[#-- Primary is used on component attributes --]
[#assign DOMAIN_ROLE_PRIMARY="primary" ]

[#-- Secondaries allow a smooth transition from one domain to another --]
[#assign DOMAIN_ROLE_SECONDARY="secondary" ]

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

[#function isPrimaryDomain domainObject]
    [#return domain.Role == DOMAIN_ROLE_PRIMARY ]
[/#function]

[#function isSecondaryDomain domainObject]
    [#return domain.Role == DOMAIN_ROLE_SECONDARY ]
[/#function]

[#function formatSegmentDNSZoneId extensions...]
    [#return formatSegmentResourceId(
                "dnszone",
                extensions)]
[/#function]


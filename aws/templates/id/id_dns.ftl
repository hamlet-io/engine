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

[#function formatSegmentDNSZoneId extensions...]
    [#return formatSegmentResourceId(
                "dnszone",
                extensions)]
[/#function]


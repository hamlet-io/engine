[#-- Web Application Firewall --]

[#-- Resources --]

[#function formatWAFIPSetId group]
    [#return formatAccountResourceId(
                "wafIpSet",
                group)]
[/#function]

[#function formatWAFRuleId ids...]
    [#return formatResourceId(
                "wafRule",
                ids)]
[/#function]

[#function formatDependentWAFRuleId resourceId extensions...]
    [#return formatDependentResourceId(
                "wafRule",
                resourceId,
                extensions)]
[/#function]

[#function formatWAFIPSetRuleId group]
    [#return formatDependentWAFRuleId(
                formatWAFIPSetId(group))]
[/#function]

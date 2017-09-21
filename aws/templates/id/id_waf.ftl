[#-- Web Application Firewall --]

[#-- Resources --]

[#assign WAF_IPSET_RESOURCE_TYPE = "wafIpSet" ]
[#assign WAF_RULE_RESOURCE_TYPE = "wafRule" ]
[#assign WAF_ACL_RESOURCE_TYPE = "wafAcl" ]

[#function formatWAFIPSetId group]
    [#return formatAccountResourceId(
                WAF_IPSET_RESOURCE_TYPE,
                group)]
[/#function]

[#function formatWAFRuleId ids...]
    [#return formatResourceId(
                WAF_RULE_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentWAFRuleId resourceId extensions...]
    [#return formatDependentResourceId(
                WAF_RULE_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatWAFIPSetRuleId group]
    [#return formatDependentWAFRuleId(
                formatWAFIPSetId(group))]
[/#function]

[#function formatWAFAclId ids...]
    [#return formatResourceId(
                WAF_ACL_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentWAFAclId resourceId extensions...]
    [#return formatDependentResourceId(
                WAF_ACL_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]


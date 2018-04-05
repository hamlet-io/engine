[#-- Web Application Firewall --]

[#-- Resources --]
[#assign AWS_WAF_IPSET_RESOURCE_TYPE = "wafIpSet" ]
[#assign AWS_WAF_RULE_RESOURCE_TYPE = "wafRule" ]
[#assign AWS_WAF_ACL_RESOURCE_TYPE = "wafAcl" ]

[#function formatWAFIPSetId group]
    [#return formatAccountResourceId(
                AWS_WAF_IPSET_RESOURCE_TYPE,
                group)]
[/#function]

[#function formatWAFRuleId ids...]
    [#return formatResourceId(
                AWS_WAF_RULE_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentWAFRuleId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_WAF_RULE_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatWAFIPSetRuleId group]
    [#return formatDependentWAFRuleId(
                formatWAFIPSetId(group))]
[/#function]

[#function formatWAFAclId ids...]
    [#return formatResourceId(
                AWS_WAF_ACL_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentWAFAclId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_WAF_ACL_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]


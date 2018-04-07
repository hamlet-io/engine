[#-- WAF IP setup --]
[#if deploymentUnit?contains("waf") && deploymentSubsetRequired("waf", true)]
    [#list getUsage("waf")?values as group]
        [#assign ipSetId = formatWAFIPSetId(group)]
        [#assign ipSetName = formatWAFIPSetName(group)]
        [#assign ipRuleId = formatWAFIPSetRuleId(group)]
        [#assign cidrs = getUsageCIDRs("waf", group.Id, false) ]
        [#if cidrs?has_content]
            [@createWAFIPSet
                listMode,
                ipSetId,
                ipSetName,
                expandCIDR(cidrs)
            /]
            [@createWAFRule
                listMode,
                ipRuleId,
                ipSetName,
                ipSetName,
                [
                    {
                        "Id" : ipSetId,
                        "Type" : "IPMatch"
                    }
                ]
            /]
        [/#if]
    [/#list]
[/#if]


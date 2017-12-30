[#-- WAF IP setup --]
[#if deploymentUnit?contains("waf") && ipAddressGroupsUsage["waf"]?has_content]
    [#if deploymentSubsetRequired("waf", true)]
        [#list ipAddressGroupsUsage["waf"]?values as group]
            [#assign ipSetId = formatWAFIPSetId(group)]
            [#assign ipSetName = formatWAFIPSetName(group)]
            [#assign ipRuleId = formatWAFIPSetRuleId(group)]
            [#assign entries = []]
            [#list group.CIDR as CIDRBlock]
                [#if !CIDRBlock?contains("0.0.0.0")]
                    [#assign entries += [CIDRBlock]]
                [/#if]
            [/#list]
            [#if entries?has_content]
                [@createWAFIPSet
                    listMode,
                    ipSetId,
                    ipSetName,
                    entries
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
[/#if]


[#-- WAF IP setup --]
[#if deploymentUnit?contains("waf")  || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("waf", true)]
        [#list ipAddressGroups?values as group]
            [#assign ipSetId = formatWAFIPSetId(group)]
            [#assign ipSetName = formatWAFIPSetName(group)]
            [#assign ipRuleId = formatWAFIPSetRuleId(group)]
            [#assign cidrs = getGroupCIDRs(group.Id, false) ]
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
[/#if]


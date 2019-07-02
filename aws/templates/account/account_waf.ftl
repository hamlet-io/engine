[#-- WAF IP setup --]
[#-- TODO(mfl): deprecate account level WAF in favour of environemnt specific WAF --]
[#if deploymentUnit?contains("waf")  || (allDeploymentUnits!false) ]
        [#if deploymentSubsetRequired("genplan", false)]
            [@addDefaultGenerationPlan subsets="template" /]
        [/#if]

    [#if deploymentSubsetRequired("waf", true)]
        [#list ipAddressGroups?values as group]
            [#assign ipSetId = formatWAFIPSetId(group)]
            [#assign ipSetName = formatWAFIPSetName(group)]
            [#assign ipRuleId = formatWAFIPSetRuleId(group)]
            [#assign cidrs = getGroupCIDRs(group.Id, false) ]
            [#if cidrs?has_content]
                [@createWAFIPSetCondition
                    ipSetId,
                    ipSetName,
                    expandCIDR([8, 16..32], cidrs)
                /]
                [@createWAFRule
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


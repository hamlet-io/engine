[#ftl]

[#function getWAFProfileRules profile={} ruleGroups={} rules={} conditions={} ]
    [#local result = [] ]
    [#list profile.Rules![] as ruleEntry]
        [#if ruleEntry.RuleGroup?has_content]
            [#local ruleList = asArray((ruleGroups[ruleEntry.RuleGroup]["WAFRules"])![]) ]
        [#else]
            [#local ruleList = asArray(ruleEntry.Rule)]
        [/#if]
        [#list ruleList as ruleListEntry]
            [#local conditionList = [] ]

            [#if ! rules[ruleListEntry]??  ]
                [@fatal
                    message="Could not find rule for WAF Profile"
                    context={
                        "RuleId": ruleListEntry,
                        "Profile": profile,
                        "Rules": rules
                    }
                /]
                [#continue]
            [/#if]

            [#list asArray((rules[ruleListEntry].Conditions)![]) as condition]
                [#local conditionDetail = conditions[condition.Condition]!{} ]
                [#if conditionDetail?has_content]
                    [#local conditionList += [
                        {
                            "Type" : conditionDetail.Type,
                            "Filters" : conditionDetail.Filters,
                            "Negated" : (condition.Negated!false)
                        }
                    ] ]
                [/#if]
            [/#list]
            [#local result += [
                {
                    "Conditions" : conditionList,
                    "Action" : (ruleEntry.Action)!"",
                    "Action:BLOCK": (ruleEntry["Action:BLOCK"])!{},
                    "Engine": rules[ruleListEntry].Engine,
                    "Engine:RateLimit": rules[ruleListEntry]["Engine:RateLimit"],
                    "Engine:VendorManaged" : rules[ruleListEntry]["Engine:VendorManaged"]
                } +
                attributeIfContent("NameSuffix", rules[ruleListEntry].NameSuffix!"")
            ] ]
        [/#list]
    [/#list]
    [#return result]
[/#function]

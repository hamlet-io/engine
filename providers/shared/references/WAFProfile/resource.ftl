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
            [#list asArray((rules[ruleListEntry].Conditions))![] as condition]
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
                    "Action" : ruleEntry.Action
                } +
                attributeIfContent("NameSuffix", rules[ruleListEntry].NameSuffix!"")
            ] ]
        [/#list]
    [/#list]
    [#return result]
[/#function]
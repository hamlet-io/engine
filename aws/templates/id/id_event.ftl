[#-- Event --]

[#assign EVENT_RULE_RESOURCE_TYPE = "event" ]

[#function formatEventRuleId occurrence extensions...]
    [#return formatResourceId(
                EVENT_RULE_RESOURCE_TYPE,
                occurrence.Core.Id,
                extensions)]
[/#function]

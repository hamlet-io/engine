[#-- Event --]

[#-- Resources --]
[#assign AWS_EVENT_RULE_RESOURCE_TYPE = "event" ]

[#function formatEventRuleId occurrence extensions...]
    [#return formatResourceId(
                AWS_EVENT_RULE_RESOURCE_TYPE,
                occurrence.Core.Id,
                extensions)]
[/#function]

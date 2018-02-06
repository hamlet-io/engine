[#-- Event --]

[#assign EVENT_RESOURCE_TYPE = "event" ]
[#assign EVENT_RULE_RESOURCE_TYPE = "event" ]

[#function formatEventId tier component extensions...]
    [#return formatComponentResourceId(
                EVENT_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatEventRuleId tier component fn extensions...]
    [#return formatComponentResourceId(
                EVENT_RULE_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                fn)]
[/#function]

[#function formatEventRuleArn ruleId account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatRegionalArn(
            "event",
            getReference(ruleId))]
[/#function]
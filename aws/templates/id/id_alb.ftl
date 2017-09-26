[#-- ALB --]

[#assign ALB_RESOURCE_TYPE = "alb" ]
[#assign ALB_LISTENER_RESOURCE_TYPE = "listener" ]
[#assign ALB_LISTENER_RULE_RESOURCE_TYPE = "listenerRule" ]
[#assign ALB_TARGET_GROUP_RESOURCE_TYPE = "tg" ]

[#function formatALBId tier component extensions...]
    [#return formatComponentResourceId(
                ALB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatALBListenerId tier component source extensions...]
    [#return formatComponentResourceId(
                ALB_LISTENER_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                source.Port)]
[/#function]

[#function formatALBListenerRuleId tier component source name extensions...]
    [#return formatComponentResourceId(
                ALB_LISTENER_RULE_RESOURCE_TYPE, 
                tier,
                component,
                extensions,
                source.Port,
                name)]
[/#function]

[#function formatALBTargetGroupId tier component source name extensions...]
    [#return formatComponentResourceId(
                ALB_TARGET_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                source.Port,
                name)]
[/#function]

[#function formatALBSecurityGroupId tier component extensions...]
    [#return formatComponentSecurityGroupId(
                tier,
                component,
                extensions)]
[/#function]

[#function formatALBListenerSecurityGroupIngressId resourceId source ]
    [#return formatDependentSecurityGroupIngressId(
                resourceId,
                source.Port)]
[/#function]

[#-- ALB --]

[#-- Resources --]

[#assign ALB_RESOURCE_TYPE = "alb" ]

[#function formatALBId tier component extensions...]
    [#return formatComponentResourceId(
                ALB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatALBListenerId tier component source extensions...]
    [#return formatComponentResourceId(
                "listener",
                tier,
                component,
                extensions,
                source.Port)]
[/#function]

[#function formatALBListenerRuleId tier component source name extensions...]
    [#return formatComponentResourceId(
                "listenerRule", 
                tier,
                component,
                extensions,
                source.Port,
                name)]
[/#function]

[#function formatALBTargetGroupId tier component source name extensions...]
    [#return formatComponentResourceId(
                "tg",
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

[#-- Attributes --]

[#function formatALBDnsId tier component extensions...]
    [#return formatDnsAttributeId(
                formatALBId(
                    tier,
                    component,
                    extensions))]
[/#function]

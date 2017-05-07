[#-- ALB --]

[#-- Resources --]

[#function formatALBId tier component extensions...]
    [#return formatComponentResourceId(
                "alb",
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
                source.Port?c)]
[/#function]

[#function formatALBListenerRuleId tier component source name extensions...]
    [#return formatComponentResourceId(
                "listenerRule", 
                tier,
                component,
                extensions,
                source.Port?c,
                name)]
[/#function]

[#function formatALBTargetGroupId tier component source name extensions...]
    [#return formatComponentResourceId(
                "tg",
                tier,
                component,
                extensions,
                source.Port?c,
                name)]
[/#function]

[#function formatALBSecurityGroupId tier component]
    [#return formatComponentSecurityGroupId(
                tier,
                component)]
[/#function]

[#function formatALBListenerSecurityGroupIngressId tier component source]
    [#return formatComponentSecurityGroupIngressId(
                tier,
                component,
                source.Port?c)]
[/#function]

[#-- Attributes --]

[#function formatALBDnsId tier component extensions...]
    [#return formatDnsAttributeId(
                formatALBId(
                    tier,
                    component,
                    extensions))]
[/#function]

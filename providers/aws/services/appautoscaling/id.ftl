[#ftl]

[#-- Resources --]
[#assign AWS_APP_AUTOSCALING_TARGET_RESOURCE_TYPE = "appautoscalingtarget" ]
[#assign AWS_APP_AUTOSCALING_POLICY_RESOURCE_TYPE = "appautoscalingpolicy" ]

[#function formatDependentAppAutoScalingPolicyId resourceId extensions... ]
    [#return formatDependentResourceId(
                AWS_APP_AUTOSCALING_POLICY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]
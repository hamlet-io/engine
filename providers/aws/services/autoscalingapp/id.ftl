[#ftl]

[#-- Resources --]
[#assign AWS_AUTOSCALING_APP_TARGET_RESOURCE_TYPE = "autoscalingapptarget" ]
[#assign AWS_APP_AUTOSCALING_POLICY_RESOURCE_TYPE = "autoscalingapppolicy" ]

[#function formatDependentAutoScalingAppPolicyId resourceId extensions... ]
    [#return formatDependentResourceId(
                AWS_APP_AUTOSCALING_POLICY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]
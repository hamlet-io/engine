[#ftl]

[#-- Resources --]
[#assign AWS_AUTOSCALING_APP_TARGET_RESOURCE_TYPE = "autoscalingapptarget" ]
[#assign AWS_AUTOSCALING_APP_POLICY_RESOURCE_TYPE = "autoscalingapppolicy" ]
[#assign AWS_AUTOSCALING_EC2_POLICY_RESOURCE_TYPE = "autoscalingec2policy" ]
[#assign AWS_AUTOSCALING_EC2_SCHEDULE_RESOURCE_TYPE = "autoscalingec2schedule" ]

[#function formatDependentAutoScalingAppPolicyId resourceId extensions... ]
    [#return formatDependentResourceId(
                AWS_AUTOSCALING_APP_POLICY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatDependentAutoScalingEc2PolicyId resourceId extensions... ]
    [#return formatDependentResourceId(
                AWS_AUTOSCALING_EC2_POLICY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatDependentAutoScalingEc2ScheduleId resourceId extensions... ]
    [#return formatDependentResourceId(
                AWS_AUTOSCALING_EC2_SCHEDULE_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]
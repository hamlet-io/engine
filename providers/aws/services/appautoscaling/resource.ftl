[#ftl]

[#assign APP_AUTOSCALING_TARGET_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign APP_AUTOSCALING_POLICY_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
] 

[#assign outputMappings +=
    {
        AWS_APP_AUTOSCALING_TARGET_RESOURCE_TYPE : APP_AUTOSCALING_TARGET_OUTPUT_MAPPINGS,
        AWS_APP_AUTOSCALING_POLICY_RESOURCE_TYPE : APP_AUTOSCALING_POLICY_OUTPUT_MAPPINGS
    }
]

[#function getAppAutoScalingEcsResourceId clusterId serviceId ]
    [#return formatRelativeUrl("service", getReference(clusterId), getReference(serviceId, NAME_ATTRIBUTE_TYPE)) ]
[/#function]

[#macro createAppAutoScalingTarget 
        id
        processorProfile
        scalingResourceId
        scalableDimension
        resourceType
        scheduledActions=[]
        roleId
        dependencies=""
        outputId=""
]

    [#local serviceNamespace = "" ]
    [#switch resourceType ]
        [#case AWS_ECS_SERVICE_RESOURCE_TYPE ]
            [#local serviceNamespace = "ecs" ]
            [#break]
        [#default]
            [#local serviceNamespace = "COTFatal: Unsupported resource type for autoscaling" ]
            [@fatal
                message="Unsupported Resource Type"
                detail={ "resourceId" : resourceId, "resourceType" : resourceType}
            /]
    [/#switch]

    [@cfResource
        id=id
        type="AWS::ApplicationAutoScaling::ScalableTarget"
        properties=
            {
                "MaxCapacity" : processorProfile.MinCount,
                "MinCapacity" : processorProfile.MaxCount,
                "ResourceId" : scalingResourceId,
                "RoleARN" : getArn(roleId),
                "ScalableDimension" : scalableDimension,
                "ServiceNamespace" : serviceNamespace
            } + 
            attributeIfContent(
                "ScheduledActions",
                scheduledActions
            )
        outputs=APP_AUTOSCALING_TARGET_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

[#function getAppAutoScalingStepAdjustment 
    adjustment
    lowerBound=""
    upperBound=""
     
]
    [#if ! lowerBound?has_content && ! upperBound?has_content ]
        [@fatal
            message="AutoScaling Step - must have upper or lower bound"
            context={ "Adjustment" : adjustment, "lowerBound" : lowerBound, "upperBound" : upperBound}
        /]
    [#return 
        [
            {
                "ScalingAdjustment" : adjustment
            } + 
            attributeIfContent(
                "MetricIntervalLowerBound",
                lowerBound
            ) + 
            attributeIfContent(
                "MetricIntervalUpperBound",
                upperBound
            )
        ]
    ]
[/#function]

[#function getAppAutoScalingStepPolicy 
    adjustmentType 
    cooldown
    metricAggregationType
    minAdjustment
    stepAdjustments
]
    [#return 
        {
            "AdjustmentType" : adjustmentType,
            "MetricAggregationType" : metricAggregationType,
            "StepAdjustments" : stepAdjustments
        } + 
        attributeIfTrue(
            "Cooldown",
            cooldown > 0,
            cooldown
        ) + 
        attributeIfTrue(
            "MinAdjustmentMagnitude",
            minAdjustment > 0,
            minAdjustment
        )
    ]
[/#function]


[#function getAppAutoScalingTrackMetric
    dimensions
    metricName
    namespace
    statistic 
]

    [#return 
        {
            "Dimensions" : dimensions,
            "MetricName" : metricName,
            "Namespace" : namespace,
            "Statistic" : statistic
        }
    ]
[/#function]

[#function getAppAutoScalingTrackPolicy 
    scaleIn
    scaleInCoolDown
    scaleOutCooldown
    targetValue
    metricSpecification
    ]

    [#return 
        {
            "CustomizedMetricSpecification" : metricSpecification,
            "TargetValue" : targetValue
        } + 
        attributeIfTrue(
            "ScaleInCooldown",
            scaleInCoolDown > 0,
            scaleInCoolDown
        ) + 
        attributeIfTrue(
            "ScaleOutCooldown",
            scaleOutCooldown > 0,
            scaleOutCooldown
        ) + 
        attributeIfTrue(
            "DisableScaleIn",
            scaleIn == false,
            true
        )
    ]
[/#function]

[#macro createAppAutoScalingPolicy
        id
        name
        policyType
        scalingPolicy
        scalingTargetId
        dependencies=""
        outputId=""
]

    [@cfResource
        id=id
        type="AWS::ApplicationAutoScaling::ScalingPolicy"
        properties= {
            "PolicyName" : name,
            "PolicyType" : policyType,
            "ScalingTargetId" : getReference(scalingTargetId),
        } + 
        attributeIfTrue(
            "StepScalingPolicyConfiguration",
            policyType?lower_case == "step",
            scalingPolicy 
        ) + 
        attributeIfTrue(
            "TargetTrackingScalingPolicyConfiguration",
            policyType?lower_case == "track",
            scalingPolicy
        )
        outputs=APP_AUTOSCALING_POLICY_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]
[#ftl]

[#assign AUTOSCALING_APP_TARGET_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign AUTOSCALING_APP_POLICY_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
] 

[#assign outputMappings +=
    {
        AWS_AUTOSCALING_APP_TARGET_RESOURCE_TYPE : AUTOSCALING_APP_TARGET_OUTPUT_MAPPINGS,
        AWS_APP_AUTOSCALING_POLICY_RESOURCE_TYPE : AUTOSCALING_APP_POLICY_OUTPUT_MAPPINGS
    }
]

[#function getAutoScalingAppEcsResourceId clusterId serviceId ]
    [#return 
        {
            "Fn::Join" : [
                "/",
                [
                    "service",
                    getReference(clusterId),
                    getReference(serviceId, NAME_ATTRIBUTE_TYPE)
                ]
            ]
        }
    ]
[/#function]

[#macro createAutoScalingAppTarget 
        id
        minCount
        maxCount
        scalingResourceId
        scalableDimension
        resourceType
        roleId
        scheduledActions=[]
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
                "MaxCapacity" : maxCount,
                "MinCapacity" : minCount,
                "ResourceId" : scalingResourceId,
                "RoleARN" : getArn(roleId),
                "ScalableDimension" : scalableDimension,
                "ServiceNamespace" : serviceNamespace
            } + 
            attributeIfContent(
                "ScheduledActions",
                scheduledActions
            )
        outputs=AUTOSCALING_APP_TARGET_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

[#function getAutoScalingAppStepAdjustment 
        adjustment
        lowerBound=""
        upperBound=""
]
    [#if ! lowerBound?has_content && ! upperBound?has_content ]
        [@fatal
            message="AutoScaling Step - must have upper or lower bound"
            context={ "Adjustment" : adjustment, "lowerBound" : lowerBound, "upperBound" : upperBound}
        /]
    [/#if]
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

[#function getAutoScalingAppStepPolicy 
    adjustmentType 
    cooldown
    metricAggregationType
    minAdjustment
    stepAdjustments
]

    [#switch adjustmentType ]
        [#case "Change" ]
            [#local adjustmentType = "ChangeInCapacity" ]
            [#break]
        [#case "Exact" ]
            [#local adjustmentType = "ExactCapacity" ]
            [#break]
        [#case "Percentage" ]
            [#local adjustmentType = "PercentChangeInCapacity" ]
            [#break]
        [#default]
            [#local adjustmentType = "COTFatal: Unsupported adjustmentType ${adjustmentType}" ]
    [/#switch]
    
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


[#function getAutoScalingAppTrackMetric
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

[#function getAutoScalingAppTrackPolicy 
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

[#macro createAutoScalingAppPolicy
        id
        name
        policyType
        scalingAction
        scalingTargetId
        dependencies=""
        outputId=""
]
    [@cfResource
        id=id
        type="AWS::ApplicationAutoScaling::ScalingPolicy"
        properties={
            "PolicyName" : name,
            "ScalingTargetId" : getReference(scalingTargetId)
        } + 
        (policyType?lower_case == "tracked")?then(
            {
                "TargetTrackingScalingPolicyConfiguration" : scalingAction,
                "PolicyType" : "TargetTrackingScaling"
            },
            {}
        ) + 
        (policyType?lower_case == "stepped")?then(
            {
                "StepScalingPolicyConfiguration" : scalingAction,
                "PolicyType" : "StepScaling"
            },
            {}
        )
        outputs=AUTOSCALING_APP_POLICY_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]
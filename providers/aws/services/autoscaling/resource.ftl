[#ftl]

[#assign AWS_AUTOSCALING_APP_TARGET_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign AWS_AUTOSCALING_APP_POLICY_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign AWS_AUTOSCALING_EC2_POLICY_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign AWS_AUTOSCALING_EC2_SCHEDULE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]


[#assign autoScalingMappings =
    {
        AWS_AUTOSCALING_APP_TARGET_RESOURCE_TYPE : AWS_AUTOSCALING_APP_TARGET_OUTPUT_MAPPINGS,
        AWS_AUTOSCALING_APP_POLICY_RESOURCE_TYPE : AWS_AUTOSCALING_APP_POLICY_OUTPUT_MAPPINGS,
        AWS_AUTOSCALING_EC2_POLICY_RESOURCE_TYPE : AWS_AUTOSCALING_EC2_POLICY_OUTPUT_MAPPINGS,
        AWS_AUTOSCALING_EC2_SCHEDULE_RESOURCE_TYPE : AWS_AUTOSCALING_EC2_SCHEDULE_OUTPUT_MAPPINGS
    }
]

[#list autoScalingMappings as type, mappings]
    [@addOutputMapping
        provider=AWS_PROVIDER
        resourceType=type
        mappings=mappings
    /]
[/#list]

[#-- Generic AutoScaling functions --]
[#function getAutoScalingStepAdjustment
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

[#function getAutoScalingCustomTrackMetric
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

[#function getAutoScalingPredefinedTrackMetric
    metricName
]

    [#return
        {
            "PredefinedMetricType" : metricName
        }
    ]
[/#function]

[#-- App AutoScaling functions --]
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

[#function getAutoScalingRDSClusterResourceId clusterId ]
    [#return
        {
            "Fn::Join" : [
                ":",
                [
                    "cluster",
                    getReference(clusterId)
                ]
            ]
        }
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


[#function getAutoScalingAppTrackPolicy
    scaleIn
    scaleInCooldown
    scaleOutCooldown
    targetValue
    specificationType
    metricSpecification
    ]

    [#return
        {
            "TargetValue" : targetValue
        } +
        attributeIfTrue(
            "ScaleInCooldown",
            scaleInCooldown > 0,
            scaleInCooldown
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
        ) +
        attributeIfTrue(
            "CustomizedMetricSpecification",
            ( specificationType == "custom" ),
            metricSpecification
        ) +
        attributeIfTrue(
            "PredefinedMetricSpecification",
            ( specificationType == "predefined" ),
            metricSpecification
        )
    ]
[/#function]

[#macro createAutoScalingAppTarget
        id
        minCount
        maxCount
        scalingResourceId
        scalableDimension
        resourceType
        scheduledActions=[]
        dependencies=""
        outputId=""
]

    [#local trustedService = "ecs.application-autoscaling.amazonaws.com" ]
    [#local serviceNamespace = "" ]
    [#switch resourceType ]
        [#case AWS_ECS_SERVICE_RESOURCE_TYPE!"" ]
            [#local serviceNamespace = "ecs" ]
            [#local serviceRoleArn = formatServiceLinkedRoleArn(trustedService, "AWSServiceRoleForApplicationAutoScaling_ECSService" ) ]
            [#break]
        [#case AWS_RDS_CLUSTER_RESOURCE_TYPE!"" ]
            [#local serviceNamespace = "rds" ]
            [#local serviceRoleArn = formatServiceLinkedRoleArn(trustedService, "AWSServiceRoleForApplicationAutoScaling_RDSCluster") ]
            [#break]
        [#default]
            [#local serviceNamespace = "COTFatal: Unsupported resource type for autoscaling" ]
            [#local serviceRoleArn = "" ]
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
                "RoleARN" : serviceRoleArn,
                "ScalableDimension" : scalableDimension,
                "ServiceNamespace" : serviceNamespace
            } +
            attributeIfContent(
                "ScheduledActions",
                scheduledActions
            )
        outputs=AWS_AUTOSCALING_APP_TARGET_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

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
        outputs=AWS_AUTOSCALING_APP_POLICY_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]


[#-- Ec2 AutoScaling functions --]
[#function getEc2AutoScalingTrackPolicy
    scaleIn
    targetValue
    metricSpecification
    ]

    [#return
        {
            "CustomizedMetricSpecification" : metricSpecification,
            "TargetValue" : targetValue
        } +
        attributeIfTrue(
            "DisableScaleIn",
            scaleIn == false,
            true
        )
    ]
[/#function]

[#macro createEc2AutoScalingSchedule
    id
    autoScaleGroupId
    schedule
    processorCount
    dependencies=""
    outputId=""
]

    [#if schedule?starts_with("cron(") ]
        [#local schedule = schedule?remove_beginning("cron(")?remove_ending(")") ]
    [#else]
        [@fatal
            message="Invalid schedule"
            detail="Provide a cron schedule in cron(* * * * * *) fromat"
        /]
    [/#if]

    [@cfResource
        id=id
        type="AWS::AutoScaling::ScheduledAction"
        properties= {
            "AutoScalingGroupName" : getReference(autoScaleGroupId),
            "DesiredCapacity" : processorCount.DesiredCount,
            "MaxSize" : processorCount.MaxCount,
            "MinSize" : processorCount.MinCount,
            "Recurrence" : schedule
        }
        outputs=AWS_AUTOSCALING_EC2_SCHEDULE_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

[#macro createEc2AutoScalingPolicy
        id
        autoScaleGroupId
        scalingAction
        policyType
        minAdjustment
        metricAggregationType=""
        adjustmentType=""
        dependencies=""
        outputId=""
]

    [#if policyType?lower_case == "stepped" ]
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
    [/#if]

    [@cfResource
        id=id
        type="AWS::AutoScaling::ScalingPolicy"
        properties= {
            "AutoScalingGroupName" : getReference(autoScaleGroupId)
        } +
        (policyType?lower_case == "tracked")?then(
            {
                "TargetTrackingConfiguration" : scalingAction,
                "PolicyType" : "TargetTrackingScaling"
            },
            {}
        ) +
        (policyType?lower_case == "stepped")?then(
            {
                "StepAdjustments" : scalingAction,
                "PolicyType" : "StepScaling",
                "AdjustmentType" : adjustmentType,
                "MetricAggregationType" : metricAggregationType
            },
            {}
        ) +
        attributeIfTrue(
            "MinAdjustmentMagnitude",
            ( minAdjustment > 0 && policyType?lower_case == "stepped") ,
            minAdjustment
        )
        outputs=AWS_AUTOSCALING_EC2_POLICY_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

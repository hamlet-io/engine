[#ftl]

[@addAttributeSet
    type=SCALINGPOLICY_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Defines the behaviour of auto scaling resources"
        }]
    attributes=[
        {
            "Names" : "Type",
            "Types" : STRING_TYPE,
            "Values" : [ "Stepped", "Tracked", "Scheduled" ],
            "Default" : "Stepped"
        },
        {
            "Names" : "Cooldown",
            "Description" : "Cooldown time ( seconds ) after a scaling event has occurred before another event can be triggered",
            "Children" : [
                {
                    "Names" : "ScaleIn",
                    "Types" : NUMBER_TYPE,
                    "Default" : 300
                },
                {
                    "Names" : "ScaleOut",
                    "Types" : NUMBER_TYPE,
                    "Default" : 600
                }
            ]
        },
        {
            "Names" : "TrackingResource",
            "Description" : "The resource metric used to trigger scaling",
            "Children" : [
                {
                    "Names" : "Link",
                    "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "MetricTrigger",
                    "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
                }
            ]
        },
        {
            "Names" : "Stepped",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "MetricAggregation",
                    "Description" : "The method used to agregate the cloudwatch metric",
                    "Types" : STRING_TYPE,
                    "Values" : [ "Average", "Minimum", "Maximum" ],
                    "Default" : "Average"
                },
                {
                    "Names" : "CapacityAdjustment",
                    "Description" : "How to scale when the policy is triggered",
                    "Types" : STRING_TYPE,
                    "Values" : [ "Change", "Exact", "Percentage" ],
                    "Default" : "Change"
                },
                {
                    "Names" : "MinAdjustment",
                    "Description" : "When minimum scale adjustment value to apply when triggered",
                    "Types" : NUMBER_TYPE,
                    "Default" : -1
                },
                {
                    "Names" : "Adjustments",
                    "Description" : "The adjustments to apply at each step",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : "LowerBound",
                            "Description" : "The lower bound for the difference between the alarm threshold and the metric",
                            "Types" : NUMBER_TYPE
                        },
                        {
                            "Names" : "UpperBound",
                            "Description" : "The upper bound for the difference between the alarm threshold and the metric",
                            "Types" : NUMBER_TYPE
                        },
                        {
                            "Names" : "AdjustmentValue",
                            "Description" : "The value to apply when the adjustment step is triggered",
                            "Types" : NUMBER_TYPE,
                            "Default" : 1
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Tracked",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "TargetValue",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "ScaleInEnabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "RecommendedMetric",
                    "Description" : "Use a recommended (predefined) metric for scaling",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Scheduled",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "ProcessorProfile",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Schedule",
                    "Types" : STRING_TYPE
                }
            ]
        }
    ]
/]

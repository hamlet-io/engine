[#-- CloudWatch --]

[#assign LOG_GROUP_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        }
    }
]
[#assign outputMappings +=
    {
        AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE : LOG_GROUP_OUTPUT_MAPPINGS
    }
]

[#macro createLogGroup mode id name retention=0]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Logs::LogGroup"
        properties=
            {
                "LogGroupName" : name
            } +
            attributeIfTrue("RetentionInDays", retention > 0, retention) +
            attributeIfTrue("RetentionInDays", (retention <= 0) && operationsExpiration?has_content, operationsExpiration)
        outputs=LOG_GROUP_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createLogMetric mode id name logGroup filter namespace value dependencies=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Logs::MetricFilter"
        properties=
            {
                "FilterPattern" : filter,
                "LogGroupName" : logGroup,
                "MetricTransformations": [
                    {
                        "MetricName": name,
                        "MetricValue": value,
                        "MetricNamespace": namespace
                    }
                ]
            }
        dependencies=dependencies
    /]
[/#macro]

[#macro createLogSubscription mode id logGroup filter destination role="" dependencies=""  ]

    [#destinationArn = destination?starts_with("arn:")?then(
        destination,
        getReference(destination, ARN_ATTRIBUTE_TYPE )
    )]

    [@cfResource
        mode=mode
        id=id
        type="AWS::Logs::SubscriptionFilter"
        properties=
            {
                "DestinationArn" : destinationArn,
                "FilterPattern" : filter,
                "LogGroupName" : logGroup
            } + 
            attributeIfContent("RoleArn", role, getReference(role) )
        dependencies=dependencies
    /]
[/#macro]

[#assign DASHBOARD_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : { 
            "UseRef" : true
        }
    }
]
[#assign outputMappings +=
    {
        AWS_CLOUDWATCH_DASHBOARD_RESOURCE_TYPE : DASHBOARD_OUTPUT_MAPPINGS
    }
]

[#macro createDashboard mode id name components ]

    [#local dashboardWidgets = [] ]
    [#local defaultTitleHeight = 1]
    [#local defaultWidgetHeight = 3]
    [#local defaultWidgetWidth = 3]
    [#local dashboardY = 0]
    [#list asArray(components) as component]
        [#local dashboardWidgets +=
            [
                {
                    "type" : "text",
                    "x" : 0,
                    "y" : dashboardY,
                    "width" : 24,
                    "height" : defaultTitleHeight,
                    "properties" : {
                        "markdown" : component.Title
                    }                    
                }
            ]
        ]
        [#local dashboardY += defaultTitleHeight]
        [#list component.Rows as row]
            [#local dashboardX = 0]
            [#if row.Title?has_content]
                [#local dashboardWidgets +=
                    [
                        {
                            "type" : "text",
                            "x" : dashboardX,
                            "y" : dashboardY,
                            "width" : defaultWidgetWidth,
                            "height" : defaultTitleHeight,
                            "properties" : {
                                "markdown" : row.Title
                            }                    
                        }
                    ]
                ]
                [#local dashboardX += defaultWidgetWidth]
            [/#if]
            [#local maxWidgetHeight = 0]
            [#list row.Widgets as widget]
                [#local widgetMetrics = []]
                [#list widget.Metrics as widgetMetric]
                    [#local widgetMetricObject =
                        [
                            widgetMetric.Namespace,
                            widgetMetric.Metric
                        ]
                    ]
                    [#if widgetMetric.Dimensions?has_content]
                        [#list widgetMetric.Dimensions as dimension]
                            [#local widgetMetricObject +=
                                [
                                    dimension.Name,
                                    dimension.Value
                                ]
                            ]
                        [/#list]
                    [/#if]
                    [#local renderingObject = {}]
                    [#if widgetMetric.Statistic?has_content]
                        [#local renderingObject += 
                            {
                                "stat" : widgetMetric.Statistic
                            }
                        ]
                    [/#if]
                    [#if widgetMetric.Period?has_content]
                        [#local renderingObject += 
                            {
                                "period" : widgetMetric.Period
                            }
                        ]
                    [/#if]
                    [#if widgetMetric.Label?has_content]
                        [#local renderingObject += 
                            {
                                "label" : widgetMetric.Period
                            }
                        ]
                    [/#if]
                    [#if renderingObject?has_content]
                        [#local widgetMetricObject += [renderingObject]]
                    [/#if]
                    [#local widgetMetrics += [widgetMetricObject]]
                [/#list]
                [#local widgetWidth = widget.Width ! defaultWidgetWidth]
                [#local widgetHeight = widget.Height ! defaultWidgetHeight]
                [#local maxWidgetHeight = (widgetHeight > maxWidgetHeight)?then(
                            widgetHeight,
                            maxWidgetHeight)]
                [#local widgetProperties =
                    {
                        "metrics" : widgetMetrics,
                        "region" : region,
                        "stat" : "Sum",
                        "period": 300,
                        "view" : widget.asGraph?has_content?then(
                                        widget.asGraph?then(
                                            "timeSeries",
                                            "singleValue"),
                                        "singleValue"),
                        "stacked" : widget.stacked ! false
                    }                    
                ]
                [#if widget.Title?has_content]
                    [#local widgetProperties +=
                        {
                            "title" : widget.Title
                        }
                    ]
                [/#if]
                [#local dashboardWidgets +=
                    [
                        {
                            "type" : "metric",
                            "x" : dashboardX,
                            "y" : dashboardY,
                            "width" : widgetWidth,
                            "height" : widgetHeight,
                            "properties" : widgetProperties
                        }
                    ]
                ]
                [#local dashboardX += widgetWidth]
            [/#list]
            [#local dashboardY += maxWidgetHeight]
        [/#list]
    [/#list]

    [@cfResource
        mode=mode
        id=id
        type="AWS::CloudWatch::Dashboard"
        properties=
            {
                "DashboardName" : name,
                "DashboardBody" :
                    getJSON(
                        {
                            "widgets" : dashboardWidgets
                        }
                    )?json_string
            }
        outputs=DASHBOARD_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createCountAlarm mode id name
            actions
            metric
            namespace
            dimensions=[]
            description=""
            threshold=1
            statistic="Sum"
            evaluationPeriods=1
            period=300
            operator="GreaterThanOrEqualToThreshold"
            missingData="notBreaching"
            reportOK=false
            dependencies=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::CloudWatch::Alarm"
        properties=
            {
                "ActionsEnabled" : true,
                "AlarmActions" : actions,
                "AlarmDescription" : description?has_content?then(description,name),
                "AlarmName" : name,
                "ComparisonOperator" : operator,
                "EvaluationPeriods" : evaluationPeriods,
                "MetricName" : metric,
                "Namespace" : namespace,
                "Period" : period,
                "Statistic" : statistic,
                "Threshold" : threshold,
                "TreatMissingData" : missingData,
                "Unit" : "Count"
            } +
            attributeIfContent("Dimensions", dimensions) +
            attributeIfTrue("OKActions", reportOK, actions)
        dependencies=dependencies
    /]
[/#macro]


[#function formatCloudWatchLogArn lgName account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatRegionalArn(
            "logs",
            lgName
        )
    ]
[/#function]
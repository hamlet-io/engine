[#ftl]

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

[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
    mappings=LOG_GROUP_OUTPUT_MAPPINGS
/]

[#-- Dummy metricAttributes to allow for log watchers --]
[#assign metricAttributes +=
    {
        AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE : {
            "Namespace" : "_productPath",
            "Dimensions" : {
                "None" : {
                    "None" : ""
                }
            }
        }
    }
]

[#macro createLogGroup id name retention=0]
    [@cfResource
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

[#macro createLogStream id name logGroup dependencies="" ]
    [@cfResource
        id=id
        type="AWS::Logs::LogStream"
        properties=
            {
                "LogGroupName" : logGroup,
                "LogStreamName" : name
            }
        dependencies=dependencies
    /]
[/#macro]

[#macro createLogMetric id name logGroup filter namespace value dependencies=""]
    [@cfResource
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

[#macro createLogSubscription id logGroupName filter destination role="" dependencies=""  ]

    [@cfResource
        id=id
        type="AWS::Logs::SubscriptionFilter"
        properties=
            {
                "DestinationArn" : getArn(destination),
                "FilterPattern" : filter,
                "LogGroupName" : logGroupName
            } +
            attributeIfContent("RoleArn", role, getArn(role) )
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

[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_CLOUDWATCH_DASHBOARD_RESOURCE_TYPE
    mappings=DASHBOARD_OUTPUT_MAPPINGS
/]

[#macro createDashboard id name components ]

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

[#macro createAlarm id
            severity
            resourceName
            alertName
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
            unit="Count"
            dependencies=""]
    [@cfResource
        id=id
        type="AWS::CloudWatch::Alarm"
        properties=
            {
                "AlarmDescription" : description?has_content?then(description,name),
                "AlarmName" : severity?upper_case + "-" + resourceName + "-" + alertName,
                "ComparisonOperator" : operator,
                "EvaluationPeriods" : evaluationPeriods,
                "MetricName" : metric,
                "Namespace" : namespace,
                "Period" : period,
                "Statistic" : statistic,
                "Threshold" : threshold,
                "TreatMissingData" : missingData,
                "Unit" : unit
            } +
            attributeIfContent(
                "Dimensions",
                dimensions
            ) +
            attributeIfTrue(
                "OKActions",
                reportOK,
                asArray(actions)
            ) +
            valueIfContent(
                {
                    "ActionsEnabled" : true,
                    "AlarmActions" : asArray(actions)
                },
                actions
            )
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

[#assign EVENT_RULE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "Attribute" : "Arn"
        }
    }
]

[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_EVENT_RULE_RESOURCE_TYPE
    mappings=EVENT_RULE_OUTPUT_MAPPINGS
/]

[#macro createScheduleEventRule id
        enabled
        scheduleExpression
        targetParameters
        dependencies="" ]

    [#if enabled ]
        [#assign state = "ENABLED" ]
    [#else]
        [#assign state = "DISABLED" ]
    [/#if]

    [@cfResource
        id=id
        type="AWS::Events::Rule"
        properties=
            {
                "ScheduleExpression" : scheduleExpression,
                "State" : state,
                "Targets" : asArray(targetParameters)
            }
        outputs=EVENT_RULE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]


[#function getCWAlertActions occurrence alertProfile alertSeverity ]
    [#local alertActions = [] ]
    [#local profileDetails = blueprintObject.AlertProfiles[alertProfile]!{} ]

    [#local alertRules = []]
    [#list profileDetails.Rules!{} as profileRule]
        [#local alertRules += [ blueprintObject.AlertRules[profileRule]!{} ]]
    [/#list]

    [#local alertSeverityDescriptions = [
        "debug",
        "info",
        "warn",
        "error",
        "fatal"
    ]]

    [#list alertSeverityDescriptions as value]
        [#if alertSeverity?lower_case?starts_with(value)]
            [#assign alertSeverityLevel = value?index]
            [#break]
        [/#if]
    [/#list]

    [#list alertRules as rule ]

        [#list alertSeverityDescriptions as value]
            [#if rule.Severity?lower_case?starts_with(value)]
                [#assign ruleSeverityLevel = value?index]
                [#break]
            [/#if]
        [/#list]

        [@debug message={ "alert" : alertSeverityLevel, "rule" : ruleSeverityLevel } enabled=true /]
        [#if alertSeverityLevel < ruleSeverityLevel ]
            [#continue]
        [/#if]

        [@debug message="Rule" context=rule enabled=true /]
        [#list rule.Destinations.Links?values as link ]

            [#if link?is_hash]
                [#local linkTarget = getLinkTarget(occurrence, link ) ]

                [@debug message="Link Target" context=linkTarget enabled=false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#local linkTargetCore = linkTarget.Core ]
                [#local linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type]
                    [#case TOPIC_COMPONENT_TYPE]
                        [#local alertActions += [ linkTargetAttributes["ARN"] ] ]
                        [#break]

                    [#default]
                        [@fatal
                            message="Unsupported alert action component"
                            detail="This component type is not supported as a cloudwatch alert destination"
                            context=link
                        /]
                [/#switch]

            [/#if]
        [/#list]
    [/#list]

    [#return alertActions ]
[/#function]

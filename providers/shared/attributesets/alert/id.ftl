[#ftl]

[@addAttributeSet
    type=ALERT_ATTRIBUTESET_TYPE
    pluralType="Alerts"
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Configuration of alerts that monitor component resources"
        }]
    attributes=[    [
        {
            "Names" : "Namespace",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "DimensionSource",
            "Description" : "The source of the alert dimensions - resource lookup or explicit configuration",
            "Types" : STRING_TYPE,
            "Values" : [ "Resource", "Configured" ],
            "Default" : "Resource"
        },
        {
            "Names" : "Resource",
            "Description" : "Provide a component resource to determine the dimensions of the metric",
            "Children" : [
                {
                    "Names" : "Id",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Type",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Dimensions",
            "Description" : "Explicit configured dimensions",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Description" : "The Key of the dimension",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Value",
                    "Description" : "The value of the dimension to match",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "SettingEnvName",
                    "Description" : "A setting name as env that will provide the dimension value",
                    "Types": STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Metric",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Statistic",
            "Types" : STRING_TYPE,
            "Default" : "Sum"
        },
        {
            "Names" : "Description",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Threshold",
            "Types" : NUMBER_TYPE,
            "Default" : 1
        },
        {
            "Names" : "Severity",
            "Types" : STRING_TYPE,
            "Values" : [ "debug", "info", "warn", "error", "fatal"],
            "Default" : "info"
        },
        {
            "Names" : "Comparison",
            "Types" : STRING_TYPE,
            "Default" : "Threshold"
        },
        {
            "Names" : "Operator",
            "Types" : STRING_TYPE,
            "Default" : "GreaterThanOrEqualToThreshold"
        },
        {
            "Names" : "Time",
            "Types" : NUMBER_TYPE,
            "Default" : 300
        },
        {
            "Names" : "Periods",
            "Types" : NUMBER_TYPE,
            "Default" : 1
        },
        {
            "Names" : "ReportOk",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "MissingData",
            "Types" : STRING_TYPE,
            "Default" : "notBreaching"
        },
        {
            "Names" : "Unit",
            "Types" : STRING_TYPE,
            "Default" : "Count"
        }
    ]
/]

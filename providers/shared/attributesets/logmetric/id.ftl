[#ftl]

[@addAttributeSet
    type=LOGMETRIC_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Generates a monitoring metric whenever the filter is matched in a log message"
        }]
    attributes=[
        {
            "Names" : "LogFilter",
            "Description" : "A filter expression to apply to logs that will trigger a metric bump",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
     ]
/]

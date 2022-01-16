[#ftl]

[@addAttributeSet
    type=TRACING_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Application tracing configuration"
        }]
    attributes=[
        {
            "Names" : "Enabled",
            "Type" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Mode",
            "Types" : STRING_TYPE,
            "Values" : [ "active", "passthrough" ]
        }
     ]
/]

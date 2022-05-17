[#ftl]

[@addAttributeSet
    type=EVENT_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Configuration of reported system notifications from component resources"
        }]
    attributes=[
        {
            "Names" : "Categories",
            "Description" : "Optional array of event categories to report",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Values" : [
                "availability", 
                "backup", 
                "configuration change", 
                "creation", 
                "deletion", 
                "failover", 
                "failure", 
                "low storage", 
                "maintenance", 
                "notification", 
                "read replica", 
                "recovery", 
                "restoration", 
                "security"
            ]
        },
        {
            "Names" : "Links",
            "SubObjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        }
    ]
/]

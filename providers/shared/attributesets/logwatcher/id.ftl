[#ftl]

[@addAttributeSet
    type=LOGWATCHER_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Configuration for services which can act on log subscriptions"
        }]
    attributes=[
        {
            "Names" : "LogFilter",
            "Description" : "A filter expression to apply to logs that will be sent to the watcher",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Links",
            "Description" : "Links to the components with logs to watch",
            "SubObjects": true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        }
     ]
/]

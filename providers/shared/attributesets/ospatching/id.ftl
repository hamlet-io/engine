[#ftl]

[@addAttributeSet
    type=OSPATCHING_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "OS Patching configuration definitions"
        }]
    attributes=[
        {
            "Names" : "Enabled",
            "Description" : "Enable automatic OS Patching",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Schedule",
            "Description" : "UTC based cron schedule to apply updates",
            "Types" : STRING_TYPE,
            "Default" : "59 13 * * *"
        },
        {
            "Names" : "SecurityOnly",
            "Description" : "Only apply security updates",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        }
    ]
/]

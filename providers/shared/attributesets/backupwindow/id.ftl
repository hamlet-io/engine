[#ftl]

[@addAttributeSet
    type=BACKUPWINDOW_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Standard Configuration options to define a backup window"
        }]
    attributes=[
        {
            "Names" : "TimeOfDay",
            "Types" : STRING_TYPE,
            "Default" : "01:00"
        },
        {
            "Names" : "TimeZone",
            "Types" : STRING_TYPE,
            "Default" : "UTC"
        }
     ]
/]

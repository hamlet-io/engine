[#ftl]

[@addAttributeSet
    type=MAINTENANCEWINDOW_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Standard Configuration options to define a maintenance window"
        }]
    attributes=[
        {
            "Names" : "DayOfTheWeek",
            "Types" : STRING_TYPE,
            "Values" : [
                "Sunday",
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday"
            ],
            "Default" : "Sunday"
        },
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

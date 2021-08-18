[#ftl]

[@addAttributeSet
    type=MAINTENANCEWINDOW_ATTRIBUTESET_TYPE
    pluralType="MaintenanceWindows"
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
            ]
        },
        {
            "Names" : "TimeOfDay",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "TimeZone",
            "Types" : STRING_TYPE
        }
     ]
/]

[#ftl]

[@addReference 
    type=LOGFILE_REFERENCE_TYPE
    pluralType="LogFiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A log file and its collection pattern"
            }
        ]
    attributes=[
        {
            "Names" : "FilePath",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "TimeFormat",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "MultiLinePattern",
            "Types" : STRING_TYPE
        }
    ]
/]
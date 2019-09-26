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
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "TimeFormat",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "MultiLinePattern",
            "Type" : STRING_TYPE
        }
    ]
/]
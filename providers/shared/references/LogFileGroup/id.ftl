[#ftl]

[@addReference 
    type=LOGFILEGROUP_REFERENCE_TYPE
    pluralType="LogFileGroups"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A group of log files"
            }
        ]
    attributes=[
        {
            "Names" : "LogFiles",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
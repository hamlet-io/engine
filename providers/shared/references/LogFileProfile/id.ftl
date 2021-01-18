[#ftl]

[@addReference 
    type=LOGFILEPROFILE_REFERENCE_TYPE
    pluralType="LogFileProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collectio of log file groups based on component type" 
            }
        ]
    attributes=[
        {
            "Names" : "*",
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "LogFileGroups",
                    "Types" : ARRAY_OF_STRING_TYPE
                }
            ]
        }
    ]
/]
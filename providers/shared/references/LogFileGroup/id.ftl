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
            "Types" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "LogStore",
            "Children" : [
                {
                    "Names" : ["Destination"],
                    "Description" : "The type of logstore to use for this log file group - component is local and link is an external store",
                    "Types" : [STRING_TYPE],
                    "Values" : ["component", "link"],
                    "Default" : "component"
                },
                {
                    "Names" : "Link",
                    "Description" : "A link to an external log store",
                    "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                }
            ]
        }
    ]
/]

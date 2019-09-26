[#ftl]

[@addReference 
    type=LOGFILTER_REFERENCE_TYPE
    pluralType="LogFilters"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A filter to apply when searching log files" 
            }
        ]
    attributes=[
        {
            "Names" : "Pattern",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
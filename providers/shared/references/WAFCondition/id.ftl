[#ftl]

[@addReference
    type=WAFCONDITION_REFERENCE_TYPE
    pluralType="WAFConditions"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Web Application Firewall Condition"
            }
        ]
    attributes=[
        {
            "Names" : "Type",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Filters",
            "Types" : ARRAY_OF_OBJECT_TYPE,
            "Children" : [
                {
                    "Names" : "FieldsToMatch",
                    "Types" : [ARRAY_TYPE, OBJECT_TYPE, STRING_TYPE],
                    "Children" : [
                        {
                            "Names" : "Type",
                            "Types" : STRING_TYPE,
                            "Values" : ["HEADER", "METHOD", "QUERY_STRING", "URI", "BODY", "SINGLE_QUERY_ARG", "ALL_QUERY_ARGS"]
                        },
                        {
                            "Names" : "Data",
                            "Types" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Constraints",
                    "Types" : STRING_TYPE,
                    "Values" : ["CONTAINS", "CONTAINS_WORD", "EXACTLY", "STARTS_WITH", "ENDS_WITH"]
                },
                {
                    "Names" : "Targets",
                    "Types" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Sizes",
                    "Types" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Transformations",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Values" : ["NONE", "CMD_LINE", "COMPRESS_WHITE_SPACE", "HTML_ENTITY_DECODE", "LOWERCASE", "URL_DECODE"]
                },
                {
                    "Names" : "Operators",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Values" : ["EQ", "NE", "LE", "LT", "GE", "GT"]
                }
            ]
        }
    ]
/]

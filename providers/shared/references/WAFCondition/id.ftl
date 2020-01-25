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
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Filters",
            "Type" : ARRAY_OF_OBJECT_TYPE,
            "Children" : [
                {
                    "Names" : "FieldsToMatch",
                    "Type" : [ARRAY_TYPE, OBJECT_TYPE, STRING_TYPE],
                    "Children" : [
                        {
                            "Names" : "Type",
                            "Type" : STRING_TYPE,
                            "Values" : ["HEADER", "METHOD", "QUERY_STRING", "URI", "BODY", "SINGLE_QUERY_ARG", "ALL_QUERY_ARGS"]
                        },
                        {
                            "Names" : "Data",
                            "Type" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Constraints",
                    "Type" : STRING_TYPE,
                    "Values" : ["CONTAINS", "CONTAINS_WORD", "EXACTLY", "STARTS_WITH", "ENDS_WITH"]
                },
                {
                    "Names" : "Targets",
                    "Type" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Sizes",
                    "Type" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Transformations",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Values" : ["NONE", "CMD_LINE", "COMPRESS_WHITE_SPACE", "HTML_ENTITY_DECODE", "LOWERCASE", "URL_DECODE"]
                },
                {
                    "Names" : "Operators",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Values" : ["EQ", "NE", "LE", "LT", "GE", "GT"]
                }
            ]
        }
    ]
/]

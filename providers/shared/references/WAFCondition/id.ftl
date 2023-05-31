[#ftl]

[#assign WAF_BYTE_MATCH_CONDITION_TYPE = "ByteMatch" ]
[#assign WAF_GEO_MATCH_CONDITION_TYPE = "GeoMatch" ]
[#assign WAF_IP_MATCH_CONDITION_TYPE = "IPMatch" ]
[#assign WAF_REGEX_MATCH_CONDITION_TYPE = "RegexMatch" ]
[#assign WAF_SIZE_CONSTRAINT_CONDITION_TYPE = "SizeConstraint" ]
[#assign WAF_SQL_INJECTION_MATCH_CONDITION_TYPE = "SqlInjectionMatch" ]
[#assign WAF_XSS_MATCH_CONDITION_TYPE = "XssMatch" ]
[#assign WAF_LABEL_MATCH_CONDITION_TYPE = "LabelMatch" ]


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
            "Description" : "The type of condition to use for the rule",
            "Types" : STRING_TYPE,
            "Values" : [
                WAF_BYTE_MATCH_CONDITION_TYPE,
                WAF_GEO_MATCH_CONDITION_TYPE,
                WAF_IP_MATCH_CONDITION_TYPE,
                WAF_REGEX_MATCH_CONDITION_TYPE,
                WAF_SIZE_CONSTRAINT_CONDITION_TYPE,
                WAF_SQL_INJECTION_MATCH_CONDITION_TYPE,
                WAF_XSS_MATCH_CONDITION_TYPE,
                WAF_LABEL_MATCH_CONDITION_TYPE
            ]
        },
        {
            "Names" : "Filters",
            "Types" : ARRAY_OF_OBJECT_TYPE,
            "Children" : [
                {
                    "Names" : "FieldsToMatch",
                    "Description" : "Fields in an HTTP request to search for the target",
                    "Types" : [
                        ARRAY_TYPE, OBJECT_TYPE, STRING_TYPE
                    ],
                    "Children" : [
                        {
                            "Names" : "Type",
                            "Description": "The type of field to match for",
                            "Types" : STRING_TYPE,
                            "Values" : [
                                "HEADER",
                                "METHOD",
                                "QUERY_STRING",
                                "URI",
                                "BODY",
                                "SINGLE_QUERY_ARG",
                                "ALL_QUERY_ARGS"
                            ]
                        },
                        {
                            "Names" : "Data",
                            "Description" : "Qualifying data on the field - e.g used to specify a specific header",
                            "Types" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Operators",
                    "Description" : "Used to define number based operation matching",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Values" : ["EQ", "NE", "LE", "LT", "GE", "GT"]
                },
                {
                    "Names" : "Constraints",
                    "Description" : "How to apply a match on the target",
                    "Types" : STRING_TYPE,
                    "Values" : [
                        "CONTAINS",
                        "CONTAINS_WORD",
                        "EXACTLY",
                        "STARTS_WITH",
                        "ENDS_WITH"
                    ],
                    "Default": "EXACTLY"
                },
                {
                    "Names" : "Targets",
                    "Description" : "A list of waf value sets that are used to match the condition",
                    "Types" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Sizes",
                    "Description" : "Payload sizes to use byte matching",
                    "Types" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Transformations",
                    "Description": "Transformations to perform on the target value before evaluating it",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Values" : [
                        "NONE",
                        "CMD_LINE",
                        "COMPRESS_WHITE_SPACE",
                        "HTML_ENTITY_DECODE",
                        "LOWERCASE",
                        "URL_DECODE"
                    ],
                    "Default": ["NONE"]
                },
                {
                    "Names": "Type:LabelMatch",
                    "Children" : [
                        {
                            "Names" : "Scope",
                            "Description" : "The scope of the label to match on either match on a rule namespace or an explicit label",
                            "Values" : [ "NAMESPACE", "LABEL"],
                            "Default" : "LABEL",
                            "Types" : STRING_TYPE
                        }
                    ]
                }
            ]
        }
    ]
/]

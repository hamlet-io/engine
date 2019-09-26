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
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "FildsToMatch",
                    "Children" : [
                        {
                            "Names" : "Type",
                            "Type" : STRING_TYPE
                        },
                        {
                            "Names" : "Data",
                            "Type" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Constraints",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Targets",
                    "Type" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Transformations",
                    "Type" : ARRAY_OF_STRING_TYPE
                }
            ]
        }
    ]
/]

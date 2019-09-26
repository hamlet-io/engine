[#ftl]

[@addReference 
    type=WAFRULE_REFERENCE_TYPE
    pluralType="WAFRules"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Web Application Firewall Rule" 
            }
        ]
    attributes=[
        {
            "Names" : "NameSuffix",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Conditions",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Condition",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Negated",
                    "Type" : BOOLEAN_TYPE
                }
            ]
        }
    ]
/]
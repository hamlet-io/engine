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
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Conditions",
            "Types" : ARRAY_OF_OBJECT_TYPE,
            "Children" : [
                {
                    "Names" : "Condition",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Negated",
                    "Types" : BOOLEAN_TYPE
                }
            ]
        }
    ]
/]

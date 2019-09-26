[#ftl]

[@addReference 
    type=COUNTRYGROUP_REFERENCE_TYPE
    pluralType="CountryGroups"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of Country Codes used for access control"
            }
        ]
    attributes=[
        {
            "Names" : "Locations",
            "Type" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "Blacklist",
            "Type" : BOOLEAN_TYPE
        }
    ]
/]
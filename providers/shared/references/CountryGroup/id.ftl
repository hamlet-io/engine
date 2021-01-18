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
            "Types" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "Blacklist",
            "Types" : BOOLEAN_TYPE
        }
    ]
/]
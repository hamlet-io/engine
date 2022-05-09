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

[#function getGroupCountryCodes groups blacklist=false]
    [#local codes = [] ]
    [#list asFlattenedArray(groups) as group]
        [#local groupEntry = (countryGroups[group])!{}]
        [#if (groupEntry.Blacklist!false) == blacklist ]
            [#local codes += asArray(groupEntry.Locations![]) ]
        [/#if]
    [/#list]
    [#return codes]
[/#function]

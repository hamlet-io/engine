[#ftl]

[@addReference 
    type=ALERTPROFILE_REFERENCE_TYPE
    pluralType="AlertProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of alert rules applied to a component"
            }
        ]
    attributes=[
        {
            "Names" : "Rules",
            "Types" : ARRAY_OF_STRING_TYPE          
        }
    ]
/]
[#ftl]

[@addReference
    type=TESTPROFILE_REFERENCE_TYPE
    pluralType="TestProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of test cases"
            }
        ]
    attributes=[
        {
            "Names" : "*",
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "TestCases",
                    "Types" : ARRAY_OF_STRING_TYPE
                }
            ]
        }
    ]
/]

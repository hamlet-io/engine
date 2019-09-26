[#ftl]

[@addReference 
    type=SECURITYPROFILE_REFERENCE_TYPE
    pluralType="SecurityProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Security Configuration Options" 
            }
        ]
    attributes=[
        {
            "Names" : "HTTPSProfile",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "WAFProfile",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "WAFValueSet",
            "Type" : STRING_TYPE
        }
    ]
/]
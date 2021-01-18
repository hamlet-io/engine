[#ftl]

[@addReference 
    type=CORSPROFILE_REFERENCE_TYPE
    pluralType="CORSProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Cross Origin Resource Sharing Policy"
            }
        ]
    attributes=[
        {
            "Names" : "AllowedOrigins",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "AllowedMethods",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "AllowedHeaders",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "ExposedHeaders",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "MaxAge",
            "Types" : NUMBER_TYPE,
            "Mandatory" : true
        }
    ]
/]

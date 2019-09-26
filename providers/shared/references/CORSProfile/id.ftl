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
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "AllowedMethods",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "AllowedHeaders",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "ExposedHeaders",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "MaxAge",
            "Type" : NUMBER_TYPE,
            "Mandatory" : true
        }
    ]
/]

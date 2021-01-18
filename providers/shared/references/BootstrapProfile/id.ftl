[#ftl]

[@addReference 
    type=BOOTSTRAPPROFILE_REFERENCE_TYPE
    pluralType="BootstrapProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of boostraps to apply"
            }
        ]
    attributes=[
        {
            "Names" : "*",
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "Bootstraps",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Mandatory" : true
                }
            ]
        }
    ]
/]
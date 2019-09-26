[#ftl]

[@addReference 
    type=BOOTSTRAP_REFERENCE_TYPE
    pluralType="BootstrapProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of boostraps to apply"
            }
        ]
    attributes=[
        {
            "Names" : "Bootstraps",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
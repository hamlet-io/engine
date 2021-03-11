[#ftl]

[@addLayer
    type=SOLUTION_LAYER_TYPE
    referenceLookupType=SOLUTION_LAYER_REFERENCE_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A instance of a product"
            }
        ]
    attributes=[
        {
            "Names" : "Id",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Region",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Modules",
            "SubObjects" : true,
            "Children" : moduleReferenceConfiguration
        },
        {
            "Names" : "Plugins",
            "SubObjects" : true,
            "Children" : pluginReferenceConfiguration
        },
        {
            "Names" : "MultiAZ",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "RDS",
            "Children" : [
                {
                    "Names" : "AutoMinorVersionUpgrade",
                    "Types" : BOOLEAN_TYPE
                }
            ]
        }
    ]
/]

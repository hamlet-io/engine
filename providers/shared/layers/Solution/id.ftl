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
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Modules",
            "Subobjects" : true,
            "Children" : moduleReferenceConfiguration
        },
        {
            "Names" : "MultiAZ",
            "Type" : BOOLEAN_TYPE
        },
        {
            "Names" : "RDS",
            "Children" : [
                {
                    "Names" : "AutoMinorVersionUpgrade",
                    "Type" : BOOLEAN_TYPE
                }
            ]
        }
    ]
/]

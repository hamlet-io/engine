[#ftl]

[@addLayer
    type=SOLUTION_LAYER_TYPE
    referenceLookupType=SOLUTION_LAYER_REFERENCE_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "The solution layer"
            }
        ]
    inputFilterAttributes=[
            {
                "Id" : SOLUTION_LAYER_TYPE,
                "Description" : "The solution"
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
            "AttributeSet" : MODULE_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Plugins",
            "SubObjects" : true,
            "AttributeSet" : PLUGIN_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "LinkRefs",
            "SubObjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        }
    ]
/]

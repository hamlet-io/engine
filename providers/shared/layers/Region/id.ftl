[#ftl]

[@addLayer
    type=REGION_LAYER_TYPE
    referenceLookupType=REGION_LAYER_REFERENCE_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "An deployment provider region"
            }
        ]
    inputFilterAttributes=[
            {
                "Id" : REGION_LAYER_TYPE,
                "Description" : "The deployment provider region"
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
        }
    ]
/]

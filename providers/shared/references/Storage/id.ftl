[#ftl]

[@addReference 
    type=STORAGE_REFERENCE_TYPE
    pluralType="Storage"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A block volume storage configuration" 
            }
        ]
    attributes=[
        {
            "Names" : "*",
            "Children" : [ 
                {
                    "Names" : "Volumes",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Device",
                            "Type" : STRING_TYPE,
                            "Mandatory" : true
                        },
                        {
                            "Names" : "Size",
                            "Type" : NUMBER_TYPE,
                            "Mandatory" : true
                        }
                    ]
                }
            ]
        }
    ]
/]
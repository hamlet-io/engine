[#ftl]

[@addReference 
    type=REGION_REFERENCE_TYPE
    pluralType="Regions"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A physical location for infrastructure deployment" 
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
            "Names" : "Partition",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Locality",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Zones",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "AWSZone",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "NetworkEndpoints",
                    "Types" : ARRAY_OF_OBJECT_TYPE
                }
            ]
        },
        {
            "Names" : "Accounts",
            "Types" : OBJECT_TYPE
        },
        {
            "Names" : "AMIs",
            "Types" : OBJECT_TYPE
        }
    ]
/]
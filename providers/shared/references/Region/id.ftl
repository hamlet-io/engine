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
            "Names" : "Partition",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Locality",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Zones",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "AWSZone",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "NetworkEndpoints",
                    "Type" : ARRAY_OF_OBJECT_TYPE
                }
            ]
        },
        {
            "Names" : "Accounts",
            "Type" : OBJECT_TYPE
        },
        {
            "Names" : "AMIs",
            "Type" : OBJECT_TYPE
        }
    ]
/]
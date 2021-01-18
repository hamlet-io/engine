[#ftl]

[@addReference 
    type=NETWORKENDPOINTGROUP_REFERENCE_TYPE
    pluralType="NetworkEndpointGroups"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A group of network endpoints" 
            }
        ]
    attributes=[
        {
            "Names" : "Services",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
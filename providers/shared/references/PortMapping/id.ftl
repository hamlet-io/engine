[#ftl]

[@addReference 
    type=PORTMAPPING_REFERENCE_TYPE
    pluralType="PortMappings"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A mapping between two ports when dealing with translation or offload services"
            }
        ]
    attributes=[
        {
            "Names" : "Source",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Destination",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
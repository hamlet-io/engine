[#ftl]

[@addReference 
    type=IPADDRESSGROUP_REFERENCE_TYPE
    pluralType="IPAddressGroups"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of CIDR based IP Addresses used for access control"
            }
        ]
    attributes=[
        {
            "Names" : "CIDR",
            "Type" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "Description",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "IsOpen",
            "Type" : BOOLEAN_TYPE
        }
    ]
/]
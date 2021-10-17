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
            "Types" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "Description",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "IsOpen",
            "Types" : BOOLEAN_TYPE
        }
    ]
/]

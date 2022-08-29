[#ftl]

[@addAttributeSet
    type=HOSTNAME_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Control the information include in the host part of a Fully qualified domain name"
        }]
    attributes=[
        {
            "Names" : "Host",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "HostParts",
            "Types" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "IncludeInHost",
            "Children" : [
                {
                    "Names" : "Product",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Environment",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Segment",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Tier",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Component",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Instance",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Version",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Host",
                    "Types" : BOOLEAN_TYPE
                }
            ]
        }
    ]
/]

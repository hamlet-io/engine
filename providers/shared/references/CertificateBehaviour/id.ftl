[#ftl]

[@addReference 
    type=CERTIFICATEBEHAVIOUR_REFERNCE_TYPE
    pluralType="CertificateBehaviours"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "How to format the hostname used in a certificate"
            }
        ]
    attributes=[
        {
            "Names" : "External",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "Wildcard",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "IncludeInHost",
            "Children" : [
                {
                    "Names" : "Product",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Segment",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Tier",
                    "Types" : BOOLEAN_TYPE
                }
            ]
        },
        {
            "Names" : "HostParts",
            "Types" : ARRAY_OF_STRING_TYPE
        }
    ]
/]
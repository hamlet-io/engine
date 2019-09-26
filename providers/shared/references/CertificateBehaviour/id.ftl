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
            "Type" : BOOLEAN_TYPE
        },
        {
            "Names" : "Wildcard",
            "Type" : BOOLEAN_TYPE
        },
        {
            "Names" : "IncludeInHost",
            "Children" : [
                {
                    "Names" : "Product",
                    "Type" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Segment",
                    "Type" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Tier",
                    "Type" : BOOLEAN_TYPE
                }
            ]
        },
        {
            "Names" : "HostParts",
            "Type" : ARRAY_OF_STRING_TYPE
        }
    ]
/]
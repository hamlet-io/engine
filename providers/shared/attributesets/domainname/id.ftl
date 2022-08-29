[#ftl]

[@addAttributeSet
    type=DOMAINNAME_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "The base domain and contextual information to include in domain names"
        }]
    attributes=[
        {
            "Names" : "Domain",
            "Description" : "Explicit domain id which will override the product domain",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "IncludeInDomain",
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
                }
            ]
        }
    ]
/]

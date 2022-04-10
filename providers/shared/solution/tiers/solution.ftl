[#ftl]

[@extendSolutionConfiguration
    id="Tiers"
    provider=SHARED_PROVIDER
    attributes=[
        {
            "Names" : "Tiers",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Network",
                    "Children" : [
                        {
                            "Names" : "Link",
                            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                        },
                        {
                            "Names" : "RouteTable",
                            "Types" : STRING_TYPE
                        },
                        {
                            "Names" : "NetworkACL",
                            "Types" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Components",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : "*",
                            "Types" : OBJECT_TYPE
                        }
                    ]
                }
            ]
        }
    ]
/]

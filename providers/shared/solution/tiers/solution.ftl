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
                    "Names" : "Index",
                    "Description" : "A unique index number used when ordering tiers",
                    "Types" : NUMBER_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Active",
                    "Description" : "Defines if the layer should be used. Automatically true if components are defined",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Network",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
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
                    "Types" : ANY_TYPE
                }
            ]
        }
    ]
/]

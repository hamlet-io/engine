[#ftl]

[@addComponent
    type=NETWORK_ROUTER_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Provides routes between multiple networks"
            }
        ]
    attributes=
        [
            {
                "Names" : "DeploymentGroup",
                "Type" : STRING_TYPE,
                "Default" : "segment"
            },
            {
                "Names" : "Active",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "BGP",
                "Description" : "BGP specific configuration",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "ASN",
                        "Description" : "The BGP ASN ( Autonomous system ) Id of the router",
                        "Type" : NUMBER_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "ECMP",
                        "Description" : "Enabled Equal Cost multipath routing where supported",
                        "Default" : true
                    }
                ]
            }
        ]
/]

[@addChildComponent
    type=NETWORK_ROUTER_STATIC_ROUTE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A Static route defined on the router"
            }
        ]
    attributes=
        [
            {
                "Names" : "IPAddressGroups",
                "Description" : "The Destinations of the static route",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Action",
                "Description" : "How to handle the route",
                "Type" : STRING_TYPE,
                "Values" : [ "forward", "blackhole" ],
                "Default" : "forward"
            },
            {
                "Names" : "Links",
                "Description" : "Links to the routing destination",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    parent=NETWORK_ROUTER_COMPONENT_TYPE
    childAttribute="StaticRoutes"
    linkAttributes="StaticRoute"
/]

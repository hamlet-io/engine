[#ftl]

[@addComponentDeployment
    type=NETWORK_ROUTER_COMPONENT_TYPE
    defaultGroup="segment"
/]


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
                "Names" : "Active",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "BGP",
                "Description" : "BGP specific configuration",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "ASN",
                        "Description" : "The BGP ASN ( Autonomous system ) Id of the router",
                        "Types" : NUMBER_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "ECMP",
                        "Types" : BOOLEAN_TYPE,
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
                "Types" : ARRAY_OF_STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Action",
                "Description" : "How to handle the route",
                "Types" : STRING_TYPE,
                "Values" : [ "forward", "blackhole" ],
                "Default" : "forward"
            },
            {
                "Names" : "Links",
                "Description" : "Links to the routing destination",
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "metaparameter",
                    "Type" : LINK_METAPARAMETER_TYPE
                }
            }
        ]
    parent=NETWORK_ROUTER_COMPONENT_TYPE
    childAttribute="StaticRoutes"
    linkAttributes="StaticRoute"
/]

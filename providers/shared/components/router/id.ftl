[#ftl]

[@addComponent
    type=NETWORK_ROUTER_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Provides routes between multiple networks"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
    attributes=
        [
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
                        "Description" : "The private BGP ASN ( Autonomous system) Id of the router",
                        "Type" : NUMBER_TYPE,
                        "Default" : 64512
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

[#ftl]

[@addComponent
    type=NETWORK_GATEWAY_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A service providing a route to another network"
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
                "Names" : "Engine",
                "Type" : STRING_TYPE,
                "Values" : [ "natgw", "igw", "vpcendpoint", "endpoint", "router", "private" ],
                "Required" : true
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "SourceIPAddressGroups",
                "Description" : "IP Address Groups which can access this gateway",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : "EndpointScope",
                "Description" : "The scope of the endpoint gateway component",
                "Values" : [ "network", "zone" ],
                "Type" : STRING_TYPE
            },
            {
                "Names" : "EndpointType",
                "Description" : "The type of the route resource",
                "Values" : [ "Peering", "Transit", "NetworkInterface", "Instance" ]
            },
            {
                "Names" : "BGP",
                "Description" : "BGP Network routing",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "ASN",
                        "Type" : NUMBER_TYPE,
                        "Default" : 65000
                    }
                ]
            },
            {
                "Names" : "Endpoints",
                "Description" : "Endpoint Engine resources",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Zone",
                        "Description" : "The zone the endpoint belongs to",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Attribute",
                        "Description" : "The attribute of the endpoint",
                        "Type" : STRING_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "Link",
                        "Description" : "The link to the component",
                        "Children" : linkChildrenConfiguration
                    }
                ]
            },
            {
                "Names" : "DNSSupport",
                "Description" : "Configure a private DNS zone for the serivces offerred by the endpoint",
                "Type" : [ STRING_TYPE, BOOLEAN_TYPE ],
                "Values" : [ "UseNetworkConfig", "Disabled", "Enabled", true, false ],
                "Default" : "UseNetworkConfig"
            }
        ]
/]

[@addChildComponent
    type=NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A network destination offerred by the Gateway"
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
                "Names" : "IPAddressGroups",
                "Description" : "An IP Address Group reference",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "NetworkEndpointGroups",
                "Description" : "A cloud provider service group reference",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "DynamicRouting",
                "Description" : "Use dynamic routing to determine destinations",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    parent=NETWORK_GATEWAY_COMPONENT_TYPE
    childAttribute="Destinations"
    linkAttributes="Destination"
/]

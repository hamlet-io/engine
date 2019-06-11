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
/]

[@addComponentResourceGroup
    type=NETWORK_GATEWAY_COMPONENT_TYPE
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
                "Values" : [ "natgw", "igw", "vpcendpoint" ],
                "Required" : true
            },
            {
                "Names" : "SourceIPAddressGroups",
                "Description" : "IP Address Groups which can access this gateway",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
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
    parent=NETWORK_GATEWAY_COMPONENT_TYPE
    childAttribute="Destinations"
    linkAttributes="Destination"
/]

[@addComponentResourceGroup
    type=NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE
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
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]

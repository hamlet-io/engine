[#ftl]

[@addComponent
    type=APIGATEWAY_USAGEPLAN_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "provides a metered link between an API gateway and an invoking client"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "application"
            }
        ]
/]

[@addComponentResourceGroup
    type=APIGATEWAY_USAGEPLAN_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]

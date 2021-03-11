[#ftl]

[@addComponentDeployment
    type=APIGATEWAY_USAGEPLAN_COMPONENT_TYPE
    defaultGroup="application"
/]

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
    attributes=
        [
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]

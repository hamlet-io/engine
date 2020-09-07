[#ftl]

[@addComponentDeployment
    type=CONTAINERHOST_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=CONTAINERHOST_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An autoscaling container host cluster"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    attributes=[
        {
            "Names" : "Engine",
            "Type" : STRING_TYPE
        }
    ] +
    containerHostAttributes
/]
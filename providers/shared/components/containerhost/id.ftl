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
            }
        ]
    attributes=[
        {
            "Names" : "Engine",
            "Types" : STRING_TYPE
        }
    ] +
    containerHostAttributes
/]
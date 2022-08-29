[#ftl]

[@addComponent
    type=CONTAINERTASK_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A container defintion which is invoked on demand"
            }
        ]
    attributes=[
        {
            "AttributeSet": CONTAINERTASK_ATTRIBUTESET_TYPE
        }
    ]
/]

[@addComponentDeployment
    type=CONTAINERTASK_COMPONENT_TYPE
    defaultGroup="application"
/]

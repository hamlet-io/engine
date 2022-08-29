[#ftl]

[@addComponent
    type=CONTAINERSERVICE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An orchestrated container with always on scheduling"
            }
        ]
    attributes=[
        {
            "AttributeSet": CONTAINERSERVICE_ATTRIBUTESET_TYPE
        }
    ]
/]

[@addComponentDeployment
    type=CONTAINERSERVICE_COMPONENT_TYPE
    defaultGroup="application"
/]

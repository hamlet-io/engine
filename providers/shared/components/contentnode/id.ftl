[#ftl]

[@addComponent
    type=CONTENTHUB_NODE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Node for decentralised content hosting with centralised publishing"
            }
        ]
    attributes=
        [
            {
                "Names" : "DeploymentGroup",
                "Type" : STRING_TYPE,
                "Default" : "application"
            },
            {
                "Names" : "Path",
                "Children" : pathChildConfiguration
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]

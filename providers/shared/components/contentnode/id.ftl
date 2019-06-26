[#ftl]

[@addComponent
    type=CONTENTHUB_NODE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Node for decentralised content hosting with centralised publishing"
            },
            {
                "Type" : "Providers",
                "Value" : [ "github" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "application"
            }
        ]
    attributes=
        [
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

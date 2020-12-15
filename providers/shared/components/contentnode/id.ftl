[#ftl]

[@addComponentDeployment
    type=CONTENTHUB_NODE_COMPONENT_TYPE
    defaultGroup="application"
/]

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
                "Names" : "Path",
                "Children" : pathChildConfiguration
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "metaparameter",
                    "Type" : LINK_METAPARAMETER_TYPE
                }
            }
        ]
/]

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
                "AttributeSet" : CONTEXTPATH_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]

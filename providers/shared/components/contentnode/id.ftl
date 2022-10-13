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
                "Names" : "Path",
                "AttributeSet" : CONTEXTPATH_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the content node zip package",
                "AttributeSet" : IMAGE_URL_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=CONTENTHUB_NODE_COMPONENT_TYPE
    defaultGroup="application"
/]

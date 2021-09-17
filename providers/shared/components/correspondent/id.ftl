[#ftl]

[@addComponent
    type=CORRESPONDENT_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "An outbound and inbound marketing communications service such as AWS Pinpoint"
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

[@addComponentDeployment
    type=CORRESPONDENT_COMPONENT_TYPE
    defaultGroup="solution"
    defaultPriority=70
/]

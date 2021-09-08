[#ftl]

[@addComponentDeployment
    type=CORRESPONDENT_COMPONENT_TYPE
    defaultGroup="solution"
    defaultPriority=70
/]

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
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Logging",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]

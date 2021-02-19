[#ftl]

[@addComponentDeployment
    type=SQS_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=SQS_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Managed worker queue engine"
            }
        ]
    attributes=
        [
            {
                "Names" : "DelaySeconds",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "MaximumMessageSize",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "MessageRetentionPeriod",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "ReceiveMessageWaitTimeSeconds",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "DeadLetterQueue",
                "Children" : [
                    {
                        "Names" : "MaxReceives",
                        "Types" : NUMBER_TYPE,
                        "Default" : 0
                    }
                ]
            },
            {
                "Names" : "VisibilityTimeout",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "Alerts",
                "SubObjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Alert",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            }
        ]
/]

[#ftl]

[@addComponent
    type=SQS_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Managed worker queue engine"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    attributes=
        [
            {
                "Names" : "DelaySeconds",
                "Type" : NUMBER_TYPE
            },
            {
                "Names" : "MaximumMessageSize",
                "Type" : NUMBER_TYPE
            },
            {
                "Names" : "MessageRetentionPeriod",
                "Type" : NUMBER_TYPE
            },
            {
                "Names" : "ReceiveMessageWaitTimeSeconds",
                "Type" : NUMBER_TYPE
            },
            {
                "Names" : "DeadLetterQueue",
                "Children" : [
                    {
                        "Names" : "MaxReceives",
                        "Type" : NUMBER_TYPE,
                        "Default" : 0
                    }
                ]
            },
            {
                "Names" : "VisibilityTimeout",
                "Type" : NUMBER_TYPE
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            }
        ]
/]

[#ftl]

[@addComponent
    type=TOPIC_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "pub sub messaging serivce"
            }
        ]
    attributes=
        [
            {
                "Names" : "DeploymentGroup",
                "Type" : STRING_TYPE,
                "Default" : "solution"
            },
            {
                "Names" : "Encrypted",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "FixedName",
                "Type" : BOOLEAN_TYPE,
                "Description" : "Applies a fixed name to the topic instead of a randomly generated one",
                "Default" : false
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            }
        ]
/]


[@addChildComponent
    type=TOPIC_SUBSCRIPTION_COMPONENT_TYPE
    parent=TOPIC_COMPONENT_TYPE
    childAttribute="Subscriptions"
    linkAttributes="Subscription"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "subscription to a topic"
            }
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "DeliveryPolicy",
                "Children" : [
                    {
                        "Names" : "RetryAttempts",
                        "Description" : "Total number of attempts to deliver the message",
                        "Type" : NUMBER_TYPE,
                        "Default" : 10
                    },
                    {
                        "Names" : "ImmediateRetryAttempts",
                        "Description" : "Number of attempts to perform without delay",
                        "Type" : NUMBER_TYPE,
                        "Default" : 0
                    }
                    {
                        "Names" : "AttemptsBeforeBackOff",
                        "Description" : "Number of attempts before activating backoff",
                        "Type" : NUMBER_TYPE,
                        "Default" : 2
                    },
                    {
                        "Names" : "AttemptsAfterBackOff",
                        "Description" : "Number of attempts once the backoff has reached its longest delay",
                        "Type" : NUMBER_TYPE,
                        "Default" : 2
                    },
                    {
                        "Names" : "MinimumDelay",
                        "Description" : "Minimum delay in seconds between attempts",
                        "Type" : NUMBER_TYPE,
                        "Default" : 5
                    },
                    {
                        "Names" : "MaximumDelay",
                        "Description" : "Maximum delay to apply using backoff",
                        "Type" : NUMBER_TYPE,
                        "Default" : 900
                    },
                    {
                        "Names" : "BackOffMode",
                        "Description" : "How to process the backoff extensions",
                        "Type" : STRING_TYPE,
                        "Values" : [ "linear", "arithmetic", "geometric", "exponential" ],
                        "Default" : "exponential"
                    }
                ]
            },
            {
                "Names" : "RawMessageDelivery",
                "Description" : "Deliver message as received not with JSON payload strucutre",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            }
        ]
/]

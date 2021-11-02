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
                "Names" : "Encrypted",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "FixedName",
                "Types" : BOOLEAN_TYPE,
                "Description" : "Applies a fixed name to the topic instead of a randomly generated one",
                "Default" : false
            },
            {
                "Names" : "Alerts",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=TOPIC_COMPONENT_TYPE
    defaultGroup="solution"
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
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "DeliveryPolicy",
                "Children" : [
                    {
                        "Names" : "RetryAttempts",
                        "Description" : "Total number of attempts to deliver the message",
                        "Types" : NUMBER_TYPE,
                        "Default" : 10
                    },
                    {
                        "Names" : "ImmediateRetryAttempts",
                        "Description" : "Number of attempts to perform without delay",
                        "Types" : NUMBER_TYPE,
                        "Default" : 0
                    }
                    {
                        "Names" : "AttemptsBeforeBackOff",
                        "Description" : "Number of attempts before activating backoff",
                        "Types" : NUMBER_TYPE,
                        "Default" : 2
                    },
                    {
                        "Names" : "AttemptsAfterBackOff",
                        "Description" : "Number of attempts once the backoff has reached its longest delay",
                        "Types" : NUMBER_TYPE,
                        "Default" : 2
                    },
                    {
                        "Names" : "MinimumDelay",
                        "Description" : "Minimum delay in seconds between attempts",
                        "Types" : NUMBER_TYPE,
                        "Default" : 5
                    },
                    {
                        "Names" : "MaximumDelay",
                        "Description" : "Maximum delay to apply using backoff",
                        "Types" : NUMBER_TYPE,
                        "Default" : 900
                    },
                    {
                        "Names" : "BackOffMode",
                        "Description" : "How to process the backoff extensions",
                        "Types" : STRING_TYPE,
                        "Values" : [ "linear", "arithmetic", "geometric", "exponential" ],
                        "Default" : "exponential"
                    }
                ]
            },
            {
                "Names" : "Filters",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "MsgKey",
                        "Description" : "Name of the filter",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "MsgValues",
                        "Description" : "Valid values for the filter",
                        "Types" : ARRAY_OF_STRING_TYPE
                    },
                    {
                        "Names" : "Links",
                        "SubObjects" : true,
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    }
                ]
            },
            {
                "Names" : "RawMessageDelivery",
                "Description" : "Deliver message as received not with JSON payload strucutre",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            }
        ]
/]

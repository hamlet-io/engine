[#ftl]

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
                "Description" : "Hold messages for a delay before making them visible on the queue",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "MaximumMessageSize",
                "Description" : "The maximum size a message on the queue can be",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "MessageRetentionPeriod",
                "Description" : "How log messages will be kept on the queue before they are discarded",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "ReceiveMessageWaitTimeSeconds",
                "Description" : "How long a poll of the queue should wait to return items",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "DeadLetterQueue",
                "Description" : "Enables a dead letter queue for messages which reach a specified retry count",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "MaxReceives",
                        "Description" : "The maximum number of times a single message can be put back on the queue",
                        "Types" : NUMBER_TYPE,
                        "Default" : 0
                    }
                ]
            },
            {
                "Names" : "Ordering",
                "Description" : "The method for handling the ordering of messages on the queue",
                "Values" : [ "BestEffort", "FirstInFirstOut" ],
                "Types" : STRING_TYPE,
                "Default" : "BestEffort"
            },
            {
                "Names" : "VisibilityTimeout",
                "Description" : "The default timeout a message which has been taken off the queue is hidden from other workers for",
                "Types" : NUMBER_TYPE
            },
            {
                "Names" : "Alerts",
                "Description" : "Alert support for monitoring queue activity",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Extensions",
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
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
            },
            {
                "Names" : "Encryption",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description": "Enable encyrption at rest for queue storage",
                        "Types": BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names": "KeyReuseTime",
                        "Description": "When encyrption at rest is enabled how often to rotate the key",
                        "Types": NUMBER_TYPE,
                        "Default": 300
                    },
                    {
                        "Names" : "Transit",
                        "Description" : "Control encryption in Transit processing",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Description": "Force the use of encryption in transit ( HTTPS )",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            }
                        ]
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=SQS_COMPONENT_TYPE
    defaultGroup="solution"
/]

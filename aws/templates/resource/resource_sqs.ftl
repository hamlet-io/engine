[#-- SQS --]

[#assign SQS_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : { 
            "Attribute" : "QueueName"
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        },
        URL_ATTRIBUTE_TYPE : { 
            "UseRef" : true
        }
    }
]
[#assign outputMappings +=
    {
        SQS_RESOURCE_TYPE : SQS_OUTPUT_MAPPINGS
    }
]

[#macro createSQSQueue mode id name delay="" maximumSize="" retention="" receiveWait="" visibilityTimout="" dependencies=""]
    [@cfTemplate 
        mode=mode
        id=id
        type="AWS::SQS::Queue"
        properties=
            {
                "QueueName" : name
            } +
            delay?has_content?then(
                {
                    "DelaySeconds" : delay
                },
                {}
            ) +
            maximumSize?has_content?then(
                {
                    "MaximumMessageSize" : maximumSize
                },
                {}
            ) +
            retention?has_content?then(
                {
                    "MessageRetentionPeriod" : retention
                },
                {}
            ) +
            receiveWait?has_content?then(
                {
                    "ReceiveMessageWaitTimeSeconds" : receiveWait
                },
                {}
            ) +
            visibilityTimout?has_content?then(
                {
                    "VisibilityTimeout" : visibilityTimout
                },
                {}
            )
        outputs=SQS_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]



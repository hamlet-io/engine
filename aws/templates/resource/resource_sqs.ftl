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
    [@cfResource 
        mode=mode
        id=id
        type="AWS::SQS::Queue"
        properties=
            {
                "QueueName" : name
            } +
            attributeIfContent("DelaySeconds", delay) +
            attributeIfContent("MaximumMessageSize", maximumSize) +
            attributeIfContent("MessageRetentionPeriod", retention) +
            attributeIfContent("ReceiveMessageWaitTimeSeconds", receiveWait) +
            attributeIfContent("VisibilityTimeout", visibilityTimout)
        outputs=SQS_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]



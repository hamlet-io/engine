[#ftl]

[#-- Resources --]
[#assign AWS_SQS_RESOURCE_TYPE = "sqs" ]

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
        AWS_SQS_RESOURCE_TYPE : SQS_OUTPUT_MAPPINGS
    }
]

[#assign metricAttributes +=
    {
        AWS_SQS_RESOURCE_TYPE : {
            "Namespace" : "AWS/SQS",
            "Dimensions" : {
                "QueueName" : {
                    "Output" : NAME_ATTRIBUTE_TYPE
                }
            }
        }
    }
]

[#macro createSQSQueue mode id name delay="" maximumSize="" retention="" receiveWait="" visibilityTimout="" dlq="" dlqReceives=1 dependencies=""]
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
            attributeIfContent(
                "RedrivePolicy",
                dlq,
                {
                  "deadLetterTargetArn" : getReference(dlq, ARN_ATTRIBUTE_TYPE),
                  "maxReceiveCount" : dlqReceives
                }) +
            attributeIfContent("VisibilityTimeout", visibilityTimout)
        outputs=SQS_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]



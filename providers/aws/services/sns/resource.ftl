[#ftl]

[#assign SNS_TOPIC_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : {
            "Attribute" : "TopicName"
        }
    }
]
[@addOutputMapping 
    provider=AWS_PROVIDER
    resourceType=AWS_SNS_TOPIC_RESOURCE_TYPE
    mappings=SNS_TOPIC_OUTPUT_MAPPINGS
/]

[#assign metricAttributes +=
    {
        AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE : {
            "Namespace" : "AWS/SNS",
            "Dimensions" : {
                "Application" : {
                    "ResourceProperty" : "Name"
                },
                "Platform" : {
                    "ResourceProperty" : "Engine"
                }
            }
        }
    }
]

[#macro createSNSTopic id name encrypted=false kmsKeyId="" fixedName=false dependencies=[]]
    [@cfResource
        id=id
        type="AWS::SNS::Topic"
        properties=
            {
                "DisplayName" : name
            } +
            attributeIfTrue(
                "TopicName",
                fixedName,
                name
            ) + 
            attributeIfTrue(
                "KmsMasterKeyId",
                encrypted,
                getReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
            )
        outputs=SNS_TOPIC_OUTPUT_MAPPINGS
        dependencies=[]
    /]
[/#macro]

[#macro createSNSSubscription id topicId endpoint protocol rawMessageDelivery=false deliveryPolicy={} dependencies=[] ]
    [@cfResource
        id=id
        type="AWS::SNS::Subscription"
        properties=
            {
                "Endpoint" : endpoint,
                "Protocol" : protocol,
                "TopicArn" : getReference(topicId, ARN_ATTRIBUTE_TYPE)
            } + 
            attributeIfContent(
                "DeliveryPolicy",
                deliveryPolicy
            ) + 
            attributeIfTrue(
                "RawMessageDelivery",
                ( protocol == "sqs" || protocol == "http" || protocol = "https" ),
                rawMessageDelivery
            )
        dependencies=dependencies
    /]
[/#macro]


[#macro createSNSPolicy id topics statements dependencies=[] ]
    [@cfResource
        id=id
        type="AWS::SNS::TopicPolicy"
        properties=
            {
                "Topics" : getReferences(topics, ARN_ATTRIBUTE_TYPE)
            } +
            getPolicyDocument(statements)
        outputs={}
        dependencies=dependencies
    /]
[/#macro]


[#function getSNSPlatformAppAttributes roleId="" successSample="" credential="" principal="" ]
    [#return
        {
            "Attributes" : {
                "SuccessFeedbackRoleArn"    : getReference(roleId, ARN_ATTRIBUTE_TYPE),
                "FailureFeedbackRoleArn"    : getReference(roleId, ARN_ATTRIBUTE_TYPE),
                "SuccessFeedbackSampleRate" : successSample
            } +
            attributeIfContent(
                "PlatformCredential",
                credential,
                credential
            ) +
            attributeIfContent(
                "PlatformPrincipal",
                principal,
                principal
            )
            }]
[/#function]

[#function getSNSDeliveryPolicy deliveryPolicyConfig ]

    [#return {
        "healthyRetryPolicy": {
            "backoffFunction" : deliveryPolicyConfig.BackOffMode,
            "numRetries" :  deliveryPolicyConfig.RetryAttempts
        } + 
        attributeIfContent(
            "minDelayTarget",
            deliveryPolicyConfig.MinimumDelay!""
        ) +
        attributeIfContent(
            "maxDelayTarget",
            deliveryPolicyConfig.MaximumDelay!""
        ) +
        attributeIfContent(
            "numMinDelayRetries",
            deliveryPolicyConfig.AttemptsBeforeBackOff!""
        ) + 
        attributeIfContent(
            "numMaxDelayRetries",
            deliveryPolicyConfig.AttemptsAfterBackOff!""
        ) + 
        attributeIfContent(
            "numNoDelayRetries",
            deliveryPolicyConfig.numNoDelayRetries!""
        )
    }]
[/#function]
[#-- SNS --]

[#macro createSNSSubscription mode topicId endPoint protocol extensions...]
    [@cfTemplate
        mode=mode
        id=formatDependentSNSSubscriptionId(topicId, extensions)
        type="AWS::SNS::Subscription"
        properties=
            {
                "Endpoint" : endPoint,
                "Protocol" : protocol,
                "TopicArn" : getReference(topicId)
            }
    /]
[/#macro]

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
[#assign outputMappings +=
    {
        SNS_TOPIC_RESOURCE_TYPE : SNS_TOPIC_OUTPUT_MAPPINGS
    }
]

[#macro createSNSTopic mode id displayName topicName=""]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::SNS::Topic"
        properties=
            {
                    "DisplayName" : displayName
            } +
            topicName?has_content?then(
                {
                    "TopicName" : topicName
                },
                {}
            )
        outputs=SNS_TOPIC_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createSegmentSNSTopic mode id extensions...]
    [@createSNSTopic mode, id, formatName(productName, segmentName, extensions) /]
[/#macro]

[#macro createProductSNSTopic mode id extensions...]
    [@createSNSTopic mode, id, formatName(productName, extensions) /]
[/#macro]


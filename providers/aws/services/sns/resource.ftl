[#ftl]

[#macro createSNSSubscription topicId endPoint protocol extensions...]
    [@cfResource
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
        AWS_SNS_TOPIC_RESOURCE_TYPE : SNS_TOPIC_OUTPUT_MAPPINGS
    }
]

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

[#macro createSNSTopic id displayName topicName=""]
    [@cfResource
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

[#macro createSegmentSNSTopic id extensions...]
    [@createSNSTopic id, formatSegmentFullName(extensions) /]
[/#macro]

[#macro createProductSNSTopic id extensions...]
    [@createSNSTopic id, formatName(productName, extensions) /]
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
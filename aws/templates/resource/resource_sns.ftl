[#-- SNS --]

[#macro createSNSSubscription mode topicId endPoint protocol extensions...]
    [@cfResource
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
        AWS_SNS_TOPIC_RESOURCE_TYPE : SNS_TOPIC_OUTPUT_MAPPINGS
    }
]

[#macro createSNSTopic mode id displayName topicName=""]
    [@cfResource
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
    [@createSNSTopic mode, id, formatSegmentFullName(extensions) /]
[/#macro]

[#macro createProductSNSTopic mode id extensions...]
    [@createSNSTopic mode, id, formatName(productName, extensions) /]
[/#macro]


[#function getSNSPlatformAppAttributes roleId="" successSample="" credential="" principal="" ]
    [#return 
            {
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
            )]
[/#function]

[#function getSNSPlatformAppCreateCli name platform roleId successSample credential="" principal="" ]
    [#return 
        {
            "Name" : name,
            "Platform" : platform,
            "Attributes" : getSNSPlatformAppAttributes(
                                roleId,
                                successSample,
                                credential,
                                principal)
        }]
[/#function]

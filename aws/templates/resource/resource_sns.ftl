[#-- SNS --]

[#macro createSNSSubscription mode topicId endPoint protocol extensions...]
    [#assign subscriptionId = formatDependentSNSSubscriptionId(topicId, extensions)]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${subscriptionId}" : {
                "Type" : "AWS::SNS::Subscription",
                "Properties" : {
                    "Endpoint" : "${endPoint}",
                    "Protocol" : "${protocol}",
                    "TopicArn" : [@createReference topicId /]
                }
            }
            [@resourcesCreated /]
            [#break]
    [/#switch]
[/#macro]

[#macro createSNSTopic mode id displayName topicName=""]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::SNS::Topic",
                "Properties" : {
                    "DisplayName" : "${displayName}"
                    [#if topicName?has_content]
                        ,"TopicName" : "${topicName}"
                    [/#if]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id id region /]
            [@outputTopicName id region /]
            [#break]

    [/#switch]
[/#macro]

[#macro createSegmentSNSTopic mode id extensions...]
    [@createSNSTopic mode, id, formatName(productName, segmentName, extensions) /]
[/#macro]

[#macro createProductSNSTopic mode id extensions...]
    [@createSNSTopic mode, id, formatName(productName, extensions) /]
[/#macro]


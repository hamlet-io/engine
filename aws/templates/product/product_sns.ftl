[#-- SNS for product --]
[#if deploymentUnit?contains("sns")]
    [#assign topicId = formatProductSNSTopicId()]
    [@createProductSNSTopic
        topicId /]
    [@createSNSSubscription
        topicId,
        "alerts@${productDomain}",
        "email" /]
[/#if]


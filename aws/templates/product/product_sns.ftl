[#-- SNS for product --]
[#if deploymentUnit?contains("sns")]
    [#assign topicId = formatProductSNSTopicId()]
    [@createProductSNSTopic
        listMode,
        topicId /]
    [@createSNSSubscription
        listMode,
        topicId,
        "alerts@${productDomain}",
        "email" /]
[/#if]


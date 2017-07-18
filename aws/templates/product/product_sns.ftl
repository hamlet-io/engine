[#-- SNS for product --]
[#if deploymentUnit?contains("sns")]
    [#assign topicId = formatProductSNSTopicId()]
    [@createProductSNSTopic productListMode topicId /]
    [@createSNSSubscription
        productListMode,
        topicId,
        "alerts@${productDomain}",
        "email" /]
[/#if]


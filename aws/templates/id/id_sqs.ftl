[#-- SQS --]

[#assign SQS_RESOURCE_TYPE = "sqs" ]

[#function formatSQSId ids...]
    [#return formatResourceId(
                SQS_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatComponentSQSId tier component extensions...]
    [#return formatComponentResourceId(
                SQS_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

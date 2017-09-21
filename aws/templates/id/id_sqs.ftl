[#-- SQS --]

[#-- Resources --]

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

[#-- Attributes --]

[#function formatSQSArnId ids...]
    [#return formatArnAttributeId(
                formatSQSId(ids))]
[/#function]

[#function formatSQSUrlId ids...]
    [#return formatUrlAttributeId(
                formatSQSId(ids))]
[/#function]

[#function formatComponentSQSArnId tier component extensions...]
    [#return formatArnAttributeId(
                formatComponentSQSId(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatComponentSQSUrlId tier component extensions...]
    [#return formatUrlAttributeId(
                formatComponentSQSId(
                    tier,
                    component,
                    extensions))]
[/#function]



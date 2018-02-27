[#-- CONTENTHUB --]

[#assign CONTENTHUB_HUB_RESOURCE_TYPE = "contenthub" ]
[#assign CONTENTHUB_NODE_RESOURCE_TYPE = "contentnode" ]

[#function formatContentHubHubId tier component extensions...]
    [#return formatComponentResourceId(
                CONTENTHUB_HUB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]


[#function formatContentHubNodeId tier component extensions...]
    [#return formatComponentResourceId(
                CONTENTHUB_NODE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

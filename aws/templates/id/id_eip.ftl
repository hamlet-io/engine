[#-- EIP --]

[#-- Resources --]
[#assign AWS_EIP_RESOURCE_TYPE = "eip" ]
[#assign AWS_EIP_ASSOCIATION_RESOURCE_TYPE = "eipAssoc" ]

[#function formatEIPId ids...]
    [#return formatResourceId(
                AWS_EIP_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentEIPId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_EIP_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentEIPId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EIP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatComponentEIPAssociationId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EIP_ASSOCIATION_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

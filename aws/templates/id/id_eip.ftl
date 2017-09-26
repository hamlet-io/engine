[#-- EIP --]

[#assign EIP_RESOURCE_TYPE = "eip" ]
[#assign EIP_ASSOCIATION_RESOURCE_TYPE = "eipAssoc" ]

[#function formatEIPId ids...]
    [#return formatResourceId(
                EIP_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentEIPId resourceId extensions...]
    [#return formatDependentResourceId(
                EIP_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentEIPId tier component extensions...]
    [#return formatComponentResourceId(
                EIP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatComponentEIPAssociationId tier component extensions...]
    [#return formatComponentResourceId(
                EIP_ASSOCIATION_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

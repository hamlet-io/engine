[#-- EIP --]

[#-- Resources --]

[#function formatEIPId ids...]
    [#return formatResourceId(
                "eip",
                ids)]
[/#function]

[#function formatDependentEIPId resourceId extensions...]
    [#return formatDependentResourceId(
                "eip",
                resourceId,
                extensions)]
[/#function]

[#function formatComponentEIPId tier component extensions...]
    [#return formatComponentResourceId(
                "eip",
                tier,
                component,
                extensions)]
[/#function]

[#function formatComponentEIPAssociationId tier component extensions...]
    [#return formatComponentResourceId(
                "eipAssoc",
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]

[#function formatEIPIPAddressId ids...]
    [#return formatIPAddressAttributeId(
                formatEIPId(ids))]
[/#function]

[#function formatEIPAllocationId ids...]
    [#return formatAllocationAttributeId(
                formatEIPId(ids))]
[/#function]

[#function formatDependentEIPIPAddressId resourceId extensions...]
    [#return formatIPAddressAttributeId(
                formatDependentEIPId(
                    resourceId,
                    extensions))]
[/#function]

[#function formatDependentEIPAllocationId resourceId extensions...]
    [#return formatAllocationAttributeId(
                formatDependentEIPId(
                    resourceId,
                    extensions))]
[/#function]

[#function formatComponentEIPIPAddressId tier component extensions...]
    [#return formatIPAddressAttributeId(
                formatComponentEIPId(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatComponentEIPAllocationId tier component extensions...]
    [#return formatAllocationAttributeId(
                formatComponentEIPId(
                    tier,
                    component,
                    extensions))]
[/#function]


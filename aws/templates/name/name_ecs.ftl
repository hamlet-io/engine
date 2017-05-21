[#-- ECS --]

[#-- Container --]

[#-- Resources --]

[#function formatContainerName tier component host container]
    [#return formatName(
                getContainerName(container))]
[/#function]

[#function formatContainerPolicyName tier component host container]
    [#return formatName(
                getContainerName(container))]
[/#function]
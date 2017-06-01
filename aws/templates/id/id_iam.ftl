[#-- Policy --]

[#-- Resources --]

[#function formatPolicyId ids...]
    [#return formatResourceId(
                "policy",
                ids)]
[/#function]

[#function formatDependentPolicyId resourceId extensions...]
    [#return formatDependentResourceId(
                "policy",
                resourceId,
                extensions)]
[/#function]

[#function formatComponentPolicyId tier component extensions...]
    [#return formatComponentResourceId(
                "policy",
                tier,
                component,
                extensions)]
[/#function]

[#function formatRoleId ids...]
    [#return formatResourceId(
                "role",
                ids)]
[/#function]

[#function formatDependentRoleId resourceId extensions...]
    [#return formatDependentResourceId(
                "role",
                resourceId,
                extensions)]
[/#function]

[#function formatAccountRoleId type extensions...]
    [#return formatAccountResourceId(
                "role",
                type,
                extensions)]
[/#function]

[#function formatComponentRoleId tier component extensions...]
    [#return formatComponentResourceId(
                "role",
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]

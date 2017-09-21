[#-- Policy --]

[#-- Resources --]

[#assign POLICY_RESOURCE_TYPE="policy" ]
[#assign ROLE_RESOURCE_TYPE="role" ]

[#function formatPolicyId ids...]
    [#return formatResourceId(
                POLICY_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentPolicyId resourceId extensions...]
    [#return formatDependentResourceId(
                POLICY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentPolicyId tier component extensions...]
    [#return formatComponentResourceId(
                POLICY_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatRoleId ids...]
    [#return formatResourceId(
                ROLE_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentRoleId resourceId extensions...]
    [#return formatDependentResourceId(
                ROLE_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatAccountRoleId type extensions...]
    [#return formatAccountResourceId(
                ROLE_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatComponentRoleId tier component extensions...]
    [#return formatComponentResourceId(
                ROLE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

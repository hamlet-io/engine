[#-- IAM --]

[#-- Resources --]
[#assign AWS_IAM_POLICY_RESOURCE_TYPE="policy" ]
[#assign AWS_IAM_ROLE_RESOURCE_TYPE="role" ]

[#function formatPolicyId ids...]
    [#return formatResourceId(
                AWS_IAM_POLICY_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentPolicyId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_IAM_POLICY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentPolicyId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_IAM_POLICY_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatRoleId ids...]
    [#return formatResourceId(
                AWS_IAM_ROLE_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentRoleId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_IAM_ROLE_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatAccountRoleId type extensions...]
    [#return formatAccountResourceId(
                AWS_IAM_ROLE_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatComponentRoleId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_IAM_ROLE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

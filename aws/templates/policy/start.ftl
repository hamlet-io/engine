[#ftl]
[#macro policyHeader name id="" roles="" type="Policy" ]
    [#if (!containerListMode??) ||
        (containerListMode == "policy")]
        [#assign explicitPolicyId = id?has_content] 
        [#if explicitPolicyId]
            "${id}": {
                "Type" : "AWS::IAM::${type}",
                "Properties" : {
                [#if roles?has_content]
                    "Roles" :
                        [#if roles?is_sequence && (roles?size > 0)]
                            [
                                [#list roles as role]
                                    { "Ref" : "${role}" }
                                    [#if role?last != role],[/#if]
                                [/#list]
                            ]
                        [#else]
                            { "Ref" : "${roles}" }
                        [/#if]
                [/#if],
        [#else]
            {
        [/#if]
        "PolicyName" : "${name}",
        "PolicyDocument" : {
            "Version": "2012-10-17",
            "Statement": [
    [/#if]
    [#if containerListMode??]
        [#assign policyCount += 1]
    [/#if]
    [#assign statementCount = 0]
[/#macro]

[#macro policyFooter ]
    [#if (!containerListMode??) ||
        (containerListMode == "policy")]
            ]
        }
        [#if explicitPolicyId]
                }
        [/#if]
        }
    [/#if]
    [#if containerListMode??]
        [#if containerListMode == "policy"],[/#if]
        [#assign policyCount += 1]
    [/#if]
[/#macro]

[#macro policyStatement actions resources="*" effect="Allow" principals="" conditions=""]
    [#if (!containerListMode??) ||
        (containerListMode == "policy")]
        [#if statementCount > 0],[/#if]
        {
            [#if principals?has_content]
                "Principal" :
                    [#if principals?is_sequence]
                        [
                            [#list principals as principal]
                                "${principal}"
                                [#if principals?last != principal],[/#if]
                            [/#list]
                        ]
                    [#else]
                        "${principals}"
                    [/#if],
            [/#if]
            [#if conditions?has_content && conditions?is_hash]
                "Condition" : [@toJSON conditions /],
            [/#if]
            "Action" :
                [#if actions?is_sequence]
                    [
                        [#list actions as action]
                            "${action}"
                            [#if actions?last != action],[/#if]
                        [/#list]
                    ]
                [#else]
                    "${actions}"
                [/#if],
            "Resource" :
                [#if resources?is_sequence]
                    [
                        [#list resources as resource]
                            "${resource}"
                            [#if actions?last != action],[/#if]
                        [/#list]
                    ]
                [#else]
                    "${resources}"
                [/#if],
            "Effect" : "${effect}"
        }
        [#assign statementCount += 1]
    [/#if]
[/#macro]


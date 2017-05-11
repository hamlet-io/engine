[#ftl]
[#macro policyStatement actions resources effect="Allow"]
    {
        "Action" : [
            [#if actions?is_sequence]
                [#list actions as action]
                    "${action}"
                    [#if actions?last != action],[/#if]
                [/#list]
            [#else]
                "${actions}"
            [/#if]
        ],
        "Resource" : [
            [#if resources?is_sequence]
                [#list resources as resource]
                    "${resource}"
                    [#if actions?last != action],[/#if]
                [/#list]
            [#else]
                "${resources}"
            [/#if]
        ],
        "Effect" : "${effect}"
    }
[/#macro]

[#macro policyHeader id]
    "${id}": {
        "Type" : "AWS::IAM::Policy",
        "Properties" : {
            "PolicyDocument" : {
                "Version": "2012-10-17",
                "Statement": [
[/#macro]

[#macro policyFooter name roles=""]
                ]
            },
            "PolicyName" : "${containerListPolicyName}"
            [#if roles?has_content]
                ,"Roles" : [
                    [#if roles?is_sequence && (roles?size > 0)]
                        [#list roles as role]
                            { "Ref" : "${role}" }
                            [#if role?last != role],[/#if]
                        [/#list]
                    [#else]
                        { "Ref" : "${roles}" }
                    [/#if]
                ]
            [/#if]
        }
    }
[/#macro]


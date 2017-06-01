[#ftl]
[#macro policyHeader name id="" roles="" type="Policy"]
    [#if (!containerListMode??) ||
        (containerListMode == "policy")]
        [#assign explicitPolicyId = id?has_content] 
        [#if explicitPolicyId]
            "${id}": {
                "Type" : "AWS::IAM::${type}",
                "Properties" : {
                [#if roles?has_content]
                    "Roles" : [
                        [#if roles?is_sequence]
                            [#list roles as role]
                                { "Ref" : "${role}" }
                                [#sep],[/#sep]
                            [/#list]
                        [#else]
                            { "Ref" : "${roles}" }
                        [/#if]
                    ]
                [/#if],
        [#else]
            [#if policyCount > 0],[/#if]
            {
        [/#if]
        "PolicyName" : "${name}",
        "PolicyDocument" : {
            "Version": "2012-10-17",
            "Statement": [
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
    [/#if]
    [#assign policyCount += 1]
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
                                [#sep],[/#sep]
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
                            [#sep],[/#sep]
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
                            [#sep],[/#sep]
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

[#macro roleHeader id trustedServices=[] managedArns=[] path="" name="" embeddedPolicies=true ]
    [#assign policiesEmbedded = embeddedPolicies]
    [#assign policyCount = 0]
    "${id}": {
        "Type" : "AWS::IAM::Role",
        "Properties" : {
            [#assign propertyCount = 0]
            [#if trustedServices?has_content]
                "AssumeRolePolicyDocument" : {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {
                                [#if trustedServices?has_content]
                                    "Service": [
                                        [#list trustedServices as service]
                                            "${service}"
                                            [#sep],[/#sep]
                                        [/#list]
                                    ]
                                [/#if]
                            },
                            "Action": [ "sts:AssumeRole" ]
                        }
                    ]
                }
                [#assign propertyCount += 1]
            [/#if]
            [#if managedArns?has_content]
                [#if propertyCount > 0],[/#if]
                "ManagedPolicyArns" : [
                    [#list managedArns as arn]
                        "${arn}"
                        [#sep],[/#sep]
                    [/#list]
                ]
                [#assign propertyCount += 1]
            [/#if]
            [#if path?has_content]
                [#if propertyCount > 0],[/#if]
                "Path": "${path}",
                [#assign propertyCount += 1]
            [/#if]
            [#if name?has_content]
                [#if propertyCount > 0],[/#if]
                "RoleName": "${name}",
                [#assign propertyCount += 1]
            [/#if]
            [#if policiesEmbedded]
                [#if propertyCount > 0],[/#if]
                "Policies": [
            [#else]
        }
    }
            [/#if]
[/#macro]

[#macro roleFooter ]
    [#if policiesEmbedded]
            ]
    [/#if]
        }
    }
[/#macro]

[#macro role id trustedServices=[] managedArns=[] path="" name="" ]
    [@roleHeader id trustedServices managedArns path name false /]
[/#macro]

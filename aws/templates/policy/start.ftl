[#ftl]

[#macro policyStatements statements]
    [#if (!containerListMode??) ||
        (containerListMode == "policy")]
        [#list statements as statement]
            [#if statementCount > 0],[/#if]
            [@toJSON statement /]
            [#assign statementCount += 1]
        [/#list]
    [/#if]
[/#macro]

[#macro policyHeader name id="" roles="" type="Policy"]
    [#if (!containerListMode??) ||
        (containerListMode == "policy")]
        [#assign explicitPolicyId = id?has_content] 
        [#if explicitPolicyId]
            [@checkIfResourcesCreated /]
            "${id}": {
                "Type" : "AWS::IAM::${type}",
                "Properties" : {
                [#if roles?has_content]
                    "Roles" : [
                        [#list asArray(roles) as role]
                            { "Ref" : "${role}" }
                            [#sep],[/#sep]
                        [/#list]
                    ],
                [/#if]
            [@resourcesCreated /]
        [#else]
            [#if policyCount > 0],[/#if]
            {
        [/#if]
        "PolicyName" : "${name}",
        "PolicyDocument" : {
            "Version": "2012-10-17",
            "Statement": [
    [/#if]
    [#if (containerListMode?has_content &&
            containerListMode == "policyList")]
        [#if policyCount > 0],[/#if]
        "${id}"
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
    [#assign policyCount = policyCount!0 + 1 ]
[/#macro]

[#macro roleHeader
            id trustedServices=[] managedArns=[] trustedAccounts=[] condition=""
            path="" name="" multiFactor=false embeddedPolicies=true ]
    [#assign policiesEmbedded = embeddedPolicies]
    [#assign policyCount = 0]
    [@checkIfResourcesCreated /]
    "${id}": {
        "Type" : "AWS::IAM::Role",
        "Properties" : {
            [#assign propertyCount = 0]
            [#if trustedServices?has_content ||
                    trustedAccounts?has_content]
                "AssumeRolePolicyDocument" : {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {
                                [#assign principalSeen = false]
                                [#if trustedServices?has_content]
                                    "Service": [
                                        [#list trustedServices as trustedService]
                                            "${trustedService}"
                                            [#sep],[/#sep]
                                        [/#list]
                                    ]
                                    [#assign principalSeen = true]
                                [/#if]
                                [#if trustedAccounts?has_content]
                                    [#if principalSeen],[/#if]
                                    "AWS": [
                                        [#list trustedAccounts as trustedAccount]
                                            "arn:aws:iam::${trustedAccount}:root"
                                            [#sep],[/#sep]
                                        [/#list]
                                    ]
                                    [#assign principalSeen = true]
                                [/#if]
                            },
                            "Action": [ "sts:AssumeRole" ]
                            [#if multiFactor || condition?has_content]
                                ,"Condition": {
                                    [#if multiFactor]
                                        "Bool": {
                                          "aws:MultiFactorAuthPresent": "true"
                                        }
                                    [#else]
                                        ${condition}
                                    [/#if]
                                }                            
                            [/#if]
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
                "Path": "${path}"
                [#assign propertyCount += 1]
            [/#if]
            [#if name?has_content]
                [#if propertyCount > 0],[/#if]
                "RoleName": "${name}"
                [#assign propertyCount += 1]
            [/#if]
            [#if policiesEmbedded]
                [#if propertyCount > 0],[/#if]
                "Policies": [
            [#else]
        }
    }
            [/#if]
    [@resourcesCreated /]
[/#macro]

[#macro roleFooter]
    [#if policiesEmbedded]
            ]
    [/#if]
        }
    }
[/#macro]

[#macro role
            id trustedServices=[] managedArns=[] trustedAccounts=[] condition=""
            path="" name="" multiFactor=false]
    [@roleHeader
        id trustedServices managedArns trustedAccounts condition 
        path name multiFactor false /]
[/#macro]

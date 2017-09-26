[#-- IAM --]

[#function getPolicyStatement actions resources="*" principals="" conditions="" allow=true sid=""]
    [#return
        {
            "Action" : actions,
            "Resource" : resources,
            "Effect" :
                allow?then(
                    "Allow",
                    "Deny"
                )
        } +
        sid?has_content?then(
            {
                "Sid" : sid
            },
            {}
        ) +
        principals?has_content?then(
            {
                "Principal" : principals
            },
            {}
        ) +
        conditions?has_content?then(
            {
                "Condition" : conditions
            },
            {}
        )
    ]
[/#function]

[#function getPolicyDocumentContent statements version="2012-10-17" id=""]
    [#return
        {
            "Statement": asArray(statements),
            "Version": version
        } +
        id?has_content?then(
            {
                "Id" : id
            },
            {}
        )
    ]
[/#function]

[#function getPolicyDocument statements name=""]
    [#return
        {
            "PolicyDocument" : getPolicyDocumentContent(statements)
        }+
        name?has_content?then(
            {
                "PolicyName" : name
            },
            {}
        )
    ]
[/#function]

[#function formatIAMArn resource account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatGlobalArn(
            "iam",
            resource,
            account
        )
    ]
[/#function]

[#function formatAccountPrincipalArn account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatIAMArn(
            "root",
            account
        )
    ]
[/#function]

[#macro createPolicy mode id name statements roles="" users="" groups="" dependencies=[] ]
    [#local effectiveMode = mode]
    [#if containerListMode?has_content]
        [#switch mode]
            [#case "policy"]
                [#local effectiveMode = "definition"]
                [#break]
            [#case "policyList"]
                [#if policyCount > 0],[/#if]
                "${id}"
                [#break]
            [#case "definition"]
                [#local effectiveMode = ""]
                [#break]
        [/#switch]
    [/#if]
    [@cfTemplate
        mode=effectiveMode
        id=id
        type="AWS::IAM::Policy"
        properties=
            getPolicyDocument(statements, name) +
            roles?has_content?then(
                {
                    "Roles" : getReferences(roles)
                },
                {}
            )
        outputs={}
        dependencies=dependencies
    /]
    [#assign policyCount = policyCount!0 + 1 ]
[/#macro]

[#macro createSQSPolicy mode id queues statements dependencies=[] ]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::SQS::QueuePolicy"
        properties=
            {
                "Queues" : getReferences(queues, URL_ATTRIBUTE_TYPE)
            } +
            getPolicyDocument(statements)
        outputs={}
        dependencies=dependencies
    /]
    [#assign policyCount = policyCount!0 + 1]
[/#macro]

[#macro createBucketPolicy mode id bucket statements dependencies=[] ]
    [#local effectiveMode = mode]
    [#if containerListMode?has_content]
        [#switch mode]
            [#case "policy"]
                [#local effectiveMode = "definition"]
                [#break]
            [#case "policyList"]
                [#if policyCount > 0],[/#if]
                "${id}"
                [#break]
            [#case "definition"]
                [#local effectiveMode = ""]
                [#break]
        [/#switch]
    [/#if]
    [@cfTemplate
        mode=effectiveMode
        id=id
        type="AWS::S3::BucketPolicy"
        properties=
            {
                "Bucket" : (getExistingReference(bucket)?has_content)?then(getExistingReference(bucket),bucket)
            } +
            getPolicyDocument(statements)
        outputs={}
        dependencies=dependencies
    /]
    [#assign policyCount = policyCount!0 + 1]
[/#macro]

[#assign ROLE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        }
    }
]
[#assign outputMappings +=
    {
        ROLE_RESOURCE_TYPE : ROLE_OUTPUT_MAPPINGS
    }
]

[#macro createRole
            mode
            id
            trustedServices=[]
            trustedAccounts=[]
            multiFactor=false
            condition=""
            path=""
            name=""
            managedArns=[]
            policies=[]
            dependencies=[] ]

    [#local trustedAccountArns = [] ]
    [#list trustedAccounts as trustedAccount]
        [#local trustedAccountArns +=
            [
                formatAccountPrincipalArn(trustedAccount)
            ]
        ]
    [/#list]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::IAM::Role"
        properties=
            (trustedServices?has_content || trustedAccountArns?has_content)?then(
                {
                    "AssumeRolePolicyDocument" : {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Principal":
                                    trustedServices?has_content?then(
                                        {
                                            "Service": trustedServices
                                        },
                                        {}
                                    ) +
                                    trustedAccountArns?has_content?then(
                                        {
                                            "AWS": trustedAccountArns
                                        },
                                        {}
                                    ),
                                "Action": [ "sts:AssumeRole" ]
                            } +
                            multiFactor?then(
                                {
                                    "Condition": {
                                        "Bool": {
                                          "aws:MultiFactorAuthPresent": "true"
                                        }
                                    }
                                },
                                {}
                            ) + 
                            condition?has_content?then(
                                {
                                    "Condition": condition    
                                },
                                {}
                            )
                        ]
                    }
                },
                {}
            ) +
            managedArns?has_content?then(
                {
                    "ManagedPolicyArns" : managedArns
                },
                {}
            ) +
            path?has_content?then(
                {
                    "Path": path
                },
                {}
            ) +
            name?has_content?then(
                {
                    "RoleName": name
                },
                {}
            ) + 
            policies?has_content?then(
                {
                    "Policies": policies
                },
                {}
            )
        outputs=ROLE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]


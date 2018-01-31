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
        attributeIfContent("Sid", sid) +
        attributeIfContent("Principal", principals) +
        attributeIfContent("Condition", conditions)
    ]
[/#function]

[#function getPolicyDocumentContent statements version="2012-10-17" id=""]
    [#return
        {
            "Statement": asArray(statements),
            "Version": version
        } +
        attributeIfContent("Id", id)
    ]
[/#function]

[#function getPolicyDocument statements name=""]
    [#return
        {
            "PolicyDocument" : getPolicyDocumentContent(statements)
        }+
        attributeIfContent("PolicyName", name)
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
    [@cfResource
        mode=mode
        id=id
        type="AWS::IAM::Policy"
        properties=
            getPolicyDocument(statements, name) +
            attributeIfContent("Roles", roles, getReferences(roles))
        outputs={}
        dependencies=dependencies
    /]
[/#macro]

[#macro createSQSPolicy mode id queues statements dependencies=[] ]
    [@cfResource
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
[/#macro]

[#macro createBucketPolicy mode id bucket statements dependencies=[] ]
    [@cfResource
        mode=mode
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
            federatedServices=[]
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

    [@cfResource
        mode=mode
        id=id
        type="AWS::IAM::Role"
        properties=
            attributeIfTrue(
                "AssumeRolePolicyDocument",
                trustedServices?has_content || trustedAccountArns?has_content || federatedServices?has_content,
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal":
                                attributeIfContent("Service", trustedServices) +
                                attributeIfContent("AWS", trustedAccountArns) +
                                attributeIfContent("Federated", federatedServices),
                            "Action": valueIfTrue( 
                                            [ "sts:AssumeRoleWithWebIdentity" ],
                                            federatedServices?has_content,
                                            [ "sts:AssumeRole" ]
                                        )

                        } +
                        attributeIfTrue(
                            "Condition",
                            multiFactor,
                            {
                                "Bool": {
                                  "aws:MultiFactorAuthPresent": "true"
                                }
                            }) + 
                        attributeIfContent("Condition", condition)
                    ]
                }) +
            attributeIfContent("ManagedPolicyArns", managedArns) +
            attributeIfContent("Path", path) +
            attributeIfContent("RoleName", name) +
            attributeIfContent("Policies", policies)
        outputs=ROLE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]


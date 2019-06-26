[#ftl]

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
            attributeIfContent("Users", users, getReferences(users)) +
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
[/#macro]

[#assign ROLE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "Attribute" : "Arn"
        },
        NAME_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]
[#assign outputMappings +=
    {
        AWS_IAM_ROLE_RESOURCE_TYPE : ROLE_OUTPUT_MAPPINGS
    }
]

[#macro createRole
            mode
            id
            trustedServices=[]
            federatedServices=[]
            trustedAccounts=[]
            multiFactor=false
            condition={}
            path=""
            name=""
            managedArns=[]
            policies=[]
            dependencies=[] ]

    [#local trustedAccountArns = [] ]
    [#list asArray(trustedAccounts) as trustedAccount]
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
                getPolicyDocumentContent(
                    getPolicyStatement(
                        valueIfTrue(
                            [ "sts:AssumeRoleWithWebIdentity" ],
                            federatedServices?has_content,
                            [ "sts:AssumeRole" ]
                        ),
                        "",
                        attributeIfContent("Service", asArray(trustedServices)) +
                            attributeIfContent("AWS", asArray(trustedAccountArns)) +
                            attributeIfContent("Federated", asArray(federatedServices)),
                        valueIfTrue(
                            getMFAPresentCondition(),
                            multiFactor
                        ) +
                        condition
                    )
                )
            ) +
            attributeIfContent("ManagedPolicyArns", asArray(managedArns)) +
            attributeIfContent("Path", path) +
            attributeIfContent("RoleName", name) +
            attributeIfContent("Policies", asArray(policies))
        outputs=ROLE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#assign USER_OUTPUT_MAPPINGS =
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
        AWS_IAM_USER_RESOURCE_TYPE : USER_OUTPUT_MAPPINGS
    }
]

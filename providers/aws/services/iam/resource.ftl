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

[#macro createPolicy id name statements roles="" users="" groups="" dependencies=[] ]
    [@cfResource
        id=id
        type="AWS::IAM::Policy"
        properties=
            getPolicyDocument(statements, name ) +
            attributeIfContent("Users", users, getReferences(users)) +
            attributeIfContent("Roles", roles, getReferences(roles))
        dependencies=dependencies
        outputs={}
    /]
[/#macro]

[#assign MANAGED_POLICY_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]
[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_IAM_MANAGED_POLICY_RESOURCE_TYPE
    mappings=MANAGED_POLICY_OUTPUT_MAPPINGS
/]

[#macro createManagedPolicy id name statements roles="" users="" groups="" dependencies=[] ]
    [@cfResource
        id=id
        type="AWS::IAM::ManagedPolicy"
        properties=
            {
                "Description" : formatName(id, name)
            } +
            getPolicyDocument(statements ) +
            attributeIfContent("Users", users, getReferences(users)) +
            attributeIfContent("Roles", roles, getReferences(roles))
        dependencies=dependencies
        outputs=MANAGED_POLICY_OUTPUT_MAPPINGS
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
[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_IAM_ROLE_RESOURCE_TYPE
    mappings=ROLE_OUTPUT_MAPPINGS
/]

[#macro createRole
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
[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_IAM_USER_RESOURCE_TYPE
    mappings=USER_OUTPUT_MAPPINGS
/]

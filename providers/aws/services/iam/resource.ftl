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

[#macro createPolicy id name statements roles="" users="" groups="" dependencies=[] statementGrouping=4 statementLegnthLimit=800 ]

    [#local policyDocuments = []]
    [#-- IAM has a policy size limit of 2048 characters --]
    [#-- Need to make sure we break up the polciy document to meet this limit  --]
    [#-- It also has a limit of 10 policies per role or user so we can't break it up to all statements --]

    [@debug message="TopLevel size" context=getJSON(statements)?length enabled=true /]
    [#if getJSON(statements)?length gte statementLegnthLimit ]
        [#list statements?chunk(statementGrouping) as groupStatements ]
            [#if getJSON(groupStatements)?length gte statementLegnthLimit ]
                [#list groupStatements?chunk(statementGrouping / 2) as subGroupStatements ]
                    [#local policyDocuments +=
                            [
                                {
                                    "Id" : formatId( id, groupStatements?index, subGroupStatements?index),
                                    "Name" : formatName( name, groupStatements?index, subGroupStatements?index) ,
                                    "Statements" : subGroupStatements
                                }
                            ]]
                [/#list]
            [#else]
                [#local policyDocuments +=
                    [
                        {
                            "Id" : formatId(id, groupStatements?index),
                            "Name" : formatName(name, groupStatements?index ),
                            "Statements" : groupStatements
                        }
                    ]]
            [/#if]
        [/#list]
    [#else]
        [#local policyDocuments +=
            [
                {
                    "Id" : id,
                    "Name" : name,
                    "Statements" : statements
                }
            ]]
    [/#if]

    [#list policyDocuments as policyDocument ]
        [@cfResource
            id=policyDocument.Id
            type="AWS::IAM::Policy"
            properties=
                getPolicyDocument(policyDocument.Statements, policyDocument.Name ) +
                attributeIfContent("Users", users, getReferences(users)) +
                attributeIfContent("Roles", roles, getReferences(roles))
            dependencies=dependencies
        /]
    [/#list]
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

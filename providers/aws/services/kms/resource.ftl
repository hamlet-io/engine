[#ftl]

[#assign AWS_CMK_RESOURCE_TYPE = "cmk" ]
[#assign AWS_CMK_ALIAS_RESOURCE_TYPE = "cmkalias" ]

[#assign CMK_OUTPUT_MAPPINGS =
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
    resourceType=AWS_CMK_RESOURCE_TYPE
    mappings=CMK_OUTPUT_MAPPINGS
/]

[#macro createCMK id description statements rotateKeys=true outputId=""]
    [@cfResource
        id=id
        type="AWS::KMS::Key"
        properties=
            {
                "Description" : description,
                "Enabled" : true,
                "EnableKeyRotation" : rotateKeys,
                "KeyPolicy" : getPolicyDocumentContent(statements)
            }
        outputs=CMK_OUTPUT_MAPPINGS
        outputId=outputId
    /]
[/#macro]

[#macro createCMKAlias id name cmkId]

    [@cfResource
        id=id
        type="AWS::KMS::Alias"
        properties=
            {
                "AliasName" : name,
                "TargetKeyId" : getReference(cmkId, ARN_ATTRIBUTE_TYPE)
            }
        outputs={}
    /]
[/#macro]


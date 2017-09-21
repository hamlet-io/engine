[#-- KMS --]

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
[#assign outputMappings +=
    {
                CMK_RESOURCE_TYPE : CMK_OUTPUT_MAPPINGS
    }
]

[#macro createCMK mode id description statements rotateKeys=true outputId=""]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::KMS::Key"
        properties=
            {
                "Description" : description,
                "Enabled" : true,
                "EnableKeyRotation" : rotateKeys,
                "KeyPolicy" : {
                    "Version": "2012-10-17",
                    "Statement": statements
                }
            }
        outputs=CMK_OUTPUT_MAPPINGS
        outputId=outputId
    /]
[/#macro]

[#macro createCMKAlias mode id name cmkId]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::KMS::Alias"
        properties=
            {
                "AliasName" : name,
                "TargetKeyId" : getArnReference(cmkId)
            }
        outputs={}
    /]
[/#macro]


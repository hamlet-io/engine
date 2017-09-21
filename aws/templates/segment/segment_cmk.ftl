[#-- KMS --]
[#if (componentType == "cmk") &&
        deploymentSubsetRequired("cmk", true)]
    [#-- TODO: Get rid of inconsistent id usage --]
    [#assign cmkId = formatSegmentCMKTemplateId()]
    [#assign cmkAliasId = formatSegmentCMKAliasId(cmkId)]

    [@createCMK
        mode=segmentListMode
        id=cmkId
        description=formatName(productName,segmentName)
        statements=
            [
                getPolicyStatement(
                    "kms:*",
                    "*",
                    { 
                        "AWS": formatAccountPrincipalArn()
                    }
                )
            ]
        outputId=formatSegmentCMKId()
    /]
    
    [@createCMKAlias
        mode=segmentListMode
        id=cmkAliasId
        name=formatName("alias/" + productName, segmentName)
        cmkId=cmkId
    /]
[/#if]


[#-- CMK --]

[#function cmkDecryptPermission id]
    [#return
        [
            getPolicyStatement(
                "kms:Decrypt",
                getReference(id, ARN_ATTRIBUTE_TYPE))
        ]
    ]
[/#function]

[#function credentialsDecryptPermission]
    [#return cmkDecryptPermission(formatSegmentCMKId())]
[/#function]


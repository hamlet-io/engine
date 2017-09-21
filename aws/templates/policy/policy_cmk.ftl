[#-- CMK --]

[#function getCmkDecryptStatement id]
    [#return
        [
            getPolicyStatement(
                "kms:Decrypt",
                getReference(id))
        ]
    ]
[/#function]

[#macro cmkDecryptStatement id]
    [@policyStatements getCmkDecryptStatement(id) /]
[/#macro]



[#-- CMK --]

[#macro cmkDecryptStatement id]
    [@policyStatement "kms:Decrypt" getKey(id) /]
[/#macro]



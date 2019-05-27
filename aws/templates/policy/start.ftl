[#ftl]

[#-- Policy Structure --]

[#function getPolicyStatement actions resources="*" principals="" conditions="" allow=true sid="" notprincipals=""]
    [#return
        {
            "Effect" : allow?then("Allow", "Deny"),
            "Action" : actions
        } +
        attributeIfContent("Sid", sid) +
        attributeIfContent("Resource", resources) +
        attributeIfContent("Principal", principals) +
        attributeIfContent("NotPrincipal", notprincipals) +
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

[#-- Conditions --]

[#function getMFAPresentCondition ]
    [#return
        {
            "Bool": {
              "aws:MultiFactorAuthPresent": "true"
            }
        }]
[/#function]

[#function getIPCondition cidrs=[] match=true]
    [#return
        {
            match?then("IpAddress", "NotIpAddress") :
                { "aws:SourceIp": asFlattenedArray(cidrs) }
        }
    ]
[/#function]


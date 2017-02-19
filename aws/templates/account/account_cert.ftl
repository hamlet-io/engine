[#-- Generate certificate --]
[#if slice?contains("cert")]
    [#if resourceCount > 0],[/#if]
    [#switch accountListMode]
        [#case "definition"]
            "certificate" : {
                "Type" : "AWS::CertificateManager::Certificate",
                "Properties" : {
                    "DomainName" : "*.${accountDomain}",
                    "DomainValidationOptions" : [
                        {
                            "DomainName" : "*.${accountDomain}",
                            "ValidationDomain" : "${tenantObject.Domain.Validation}"
                        }
                    ]
                }
            }
            [#break]
        
        [#case "outputs"]
            "certificateX${accountDomainCertificateId}" : {
                "Value" : { "Ref" : "certificate" }
            }
            [#break]

    [/#switch]        
    [#assign resourceCount += 1]
[/#if]

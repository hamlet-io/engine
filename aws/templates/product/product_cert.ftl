[#-- Certificate --]
[#if deploymentUnit?contains("cert")]
    [#if resourceCount > 0],[/#if]
    [#switch productListMode]
        [#case "definition"]
            "certificate" : {
                "Type" : "AWS::CertificateManager::Certificate",
                "Properties" : {
                    "DomainName" : "*.${productDomain}",
                    "DomainValidationOptions" : [
                        {
                            "DomainName" : "*.${productDomain}",
                            "ValidationDomain" : "${tenantObject.Domain.Validation}"
                        }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId("certificate", productDomainCertificateId)}" : {
                "Value" : { "Ref" : "certificate" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]


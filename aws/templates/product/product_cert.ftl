[#-- Certificate --]
[#if slice?contains("cert")]
    [#if sliceCount > 0],[/#if]
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
            "certificateX${productDomainCertificateId}" : {
                "Value" : { "Ref" : "certificate" }
            }
            [#break]

    [/#switch]
    [#assign sliceCount += 1]
[/#if]


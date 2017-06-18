[#-- Certificate --]
[#if deploymentUnit?contains("cert")]
    [@checkIfResourcesCreated /]
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
    [@resourcesCreated /]
[/#if]


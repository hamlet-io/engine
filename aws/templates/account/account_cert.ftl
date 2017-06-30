[#-- Generate certificate --]
[#if deploymentUnit?contains("cert")]
    [@checkIfResourcesCreated /]
    [#switch accountListMode]
        [#case "definition"]
            "certificate" : {
                "Type" : "AWS::CertificateManager::Certificate",
                "Properties" : {
                    "DomainName" : "*.${accountDomain}",
                    "DomainValidationOptions" : [
                        {
                            "DomainName" : "*.${accountDomain}",
                            "ValidationDomain" : "${accountDomainValidation}"
                        }
                    ]
                }
            }
            [#break]
        
        [#case "outputs"]
            "${formatId("certificate", accountDomainCertificateId)}" : {
                "Value" : { "Ref" : "certificate" }
            }
            [#break]

    [/#switch]        
    [@resourcesCreated /]
[/#if]

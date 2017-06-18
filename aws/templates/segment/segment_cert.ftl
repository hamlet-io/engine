[#-- Certificate --]
[#if deploymentUnit?contains("cert")]
    [@checkIfResourcesCreated /]
    [#switch segmentListMode]
        [#case "definition"]
            "certificate" : {
                "Type" : "AWS::CertificateManager::Certificate",
                "Properties" : {
                    "DomainName" : "*.${segmentDomain}",
                    "DomainValidationOptions" : [
                        {
                            "DomainName" : "*.${segmentDomain}",
                            "ValidationDomain" : "${tenantObject.Domain.Validation}"
                        }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId("certificate", segmentDomainCertificateId)}" : {
                "Value" : { "Ref" : "certificate" }
            }
            [#break]

    [/#switch]
    [@resourcesCreated /]
[/#if]


[#-- Certificate --]
[#if deploymentUnit?contains("cert")]
    [#assign certificateId = formatCertificateId(region, segmentDomainCertificateId)]
    [#switch segmentListMode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
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
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output "certificate" certificateId /]
            [#break]

    [/#switch]
[/#if]


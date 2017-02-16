[#-- Certificate --]
[#if slice?contains("cert")]
    [#if sliceCount > 0],[/#if]
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
            "certificateX${segmentDomainCertificateId}" : {
                "Value" : { "Ref" : "certificate" }
            }
            [#break]

    [/#switch]
    [#assign sliceCount += 1]
[/#if]


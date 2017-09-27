[#-- ACM --]

[#macro createCertificate mode id domain validationDomain="" outputId=""]

    [@cfResource
        mode=mode
        id=id
        type="AWS::CertificateManager::Certificate"
        properties=
            {
                "DomainName" : domain
            } +
            attributeIfContent(
                "DomainValidationOptions",
                validationDomain,
                [
                    {
                        "DomainName" : domain,
                        "ValidationDomain" : validationDomain
                    }
                ]
                )
        outputId=outputId
    /]

[/#macro]
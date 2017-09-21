[#-- ACM --]

[#macro createCertificate mode id domain validationDomain="" outputId=""]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::CertificateManager::Certificate"
        properties=
            {
                "DomainName" : domain
            } +
            validationDomain?has_content?then(
                {
                    "DomainValidationOptions" : [
                        {
                            "DomainName" : domain,
                            "ValidationDomain" : validationDomain
                        }
                    ]
                },
                {}
            )
        outputId=outputId
    /]

[/#macro]
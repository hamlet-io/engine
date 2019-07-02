[#ftl]

[#assign CERTIFICATE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign outputMappings +=
    {
        AWS_CERTIFICATE_RESOURCE_TYPE : CERTIFICATE_OUTPUT_MAPPINGS
    }
]

[#macro createCertificate id domain validationDomain="" outputId=""]

    [@cfResource
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
        outputs=CERTIFICATE_OUTPUT_MAPPINGS
        outputId=outputId
    /]

[/#macro]
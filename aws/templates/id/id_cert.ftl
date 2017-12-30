[#-- Certificate --]

[#assign CERTIFICATE_RESOURCE_TYPE="certificate" ]

[#function formatCertificateId ids...]
    [#return formatResourceId(
                CERTIFICATE_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentCertificateId resourceId extensions...]
    [#return formatDependentResourceId(
                CERTIFICATE_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentCertificateId tier component extensions...]
    [#return formatComponentResourceId(
                CERTIFICATE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatDomainCertificateId certificateObject, hostName=""]
    [#return formatResourceId(
                CERTIFICATE_RESOURCE_TYPE,
                certificateObject.Wildcard?then(
                    "star",
                    hostName
                ),
                splitDomainName(certificateObject.Domain.Name) )]
[/#function]

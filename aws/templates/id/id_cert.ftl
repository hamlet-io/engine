[#-- Certificate --]

[#-- Resources --]
[#assign AWS_CERTIFICATE_RESOURCE_TYPE="certificate" ]

[#function formatCertificateId ids...]
    [#return formatResourceId(
                AWS_CERTIFICATE_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentCertificateId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_CERTIFICATE_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentCertificateId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_CERTIFICATE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function getCertificateDomains certificateObject]
    [#return certificateObject.Domains![] ]
[/#function]

[#function getCertificatePrimaryDomain certificateObject]
    [#list certificate.Domains as domain]
        [#if domain.Role = DOMAIN_ROLE_PRIMARY]
            [#return domain ]
            [#break]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#function formatDomainCertificateId certificateObject, hostName=""]
    [#local primaryDomain = getCertificatePrimaryDomain(certificateObject) ]
    [#return
        formatResourceId(
            AWS_CERTIFICATE_RESOURCE_TYPE,
            certificateObject.Wildcard?then(
                "star",
                hostName
            ),
            splitDomainName(primaryDomain.Name) 
        ) ]
[/#function]

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
    [#list certificateObject.Domains as domain]
        [#if isPrimaryDomain(domain) ]
            [#return domain ]
            [#break]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#function getCertificateSecondaryDomains certificateObject]
    [#local result = [] ]
    [#list certificateObject.Domains as domain]
        [#if isSecondaryDomain(domain) ]
            [#local result += [domain] ]
            [#break]
        [/#if]
    [/#list]
    [#return result ]
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

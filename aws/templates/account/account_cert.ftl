[#-- Generate certificate --]
[#if deploymentUnit?contains("cert")]
    [#assign certificateId = formatCertificateId(accountDomainCertificateId)]

    [@createCertificate
        mode=accountListMode
        id="certificate"
        domain=formatDomainName("*",accountDomain)
        validationDomain=(domains.Validation)!""
        outputId=certificateId
    /]

[/#if]

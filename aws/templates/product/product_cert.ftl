[#-- Certificate --]
[#if deploymentUnit?contains("cert")]
    [#assign certificateId = formatCertificateId(productDomainCertificateId)]

    [@createCertificate
        mode=listMode
        id="certificate"
        domain=formatDomainName("*",productDomain)
        validationDomain=(domains.Validation)!""
        outputId=certificateId
    /]

[/#if]


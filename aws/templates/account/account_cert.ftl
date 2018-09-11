[#-- Generate certificate --]
[#if deploymentUnit?contains("cert") || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("cert", true)]
        [#assign certificateId = formatCertificateId(accountDomainCertificateId)]
    
        [@createCertificate
            mode=listMode
            id="certificate"
            domain=formatDomainName("*",accountDomain)
            validationDomain=(domains.Validation)!""
            outputId=certificateId
        /]
    [/#if]
[/#if]

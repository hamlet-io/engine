[#-- Generate certificate --]
[#if getCLODeploymentUnit()?contains("cert") || (groupDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets="template" /]
    [/#if]

    [#if deploymentSubsetRequired("cert", true)]
        [#assign certificateId = formatCertificateId(accountDomainCertificateId)]

        [@createCertificate
            id="certificate"
            domain=formatDomainName("*",accountDomain)
            validationDomain=(domains.Validation)!""
            outputId=certificateId
        /]
    [/#if]
[/#if]

[#-- Generate certificate --]
[#if getDeploymentUnit()?contains("cert") || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets="template" /]
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

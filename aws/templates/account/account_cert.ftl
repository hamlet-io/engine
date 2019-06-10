[#-- Generate certificate --]
[#if deploymentUnit?contains("cert") || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
    [/#if]

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

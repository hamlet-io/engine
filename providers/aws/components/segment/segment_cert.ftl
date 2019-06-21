[#ftl]
[#macro aws_cert_cf_segment occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#if deploymentSubsetRequired("cert", true)]
        [#local certificateId = formatCertificateId(segmentDomainCertificateId)]

        [@createCertificate
            mode=listMode
            id="certificate"
            domain=formatDomainName("*",segmentDomain)
            validationDomain=(domains.Validation)!""
            outputId=certificateId
        /]
    [/#if]
[/#macro]


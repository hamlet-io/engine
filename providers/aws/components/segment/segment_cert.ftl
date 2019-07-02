[#ftl]
[#macro aws_cert_cf_segment occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets="template" /]
        [#return]
    [/#if]

    [#if deploymentSubsetRequired("cert", true)]
        [#local certificateId = formatCertificateId(segmentDomainCertificateId)]

        [@createCertificate
            id="certificate"
            domain=formatDomainName("*",segmentDomain)
            validationDomain=(domains.Validation)!""
            outputId=certificateId
        /]
    [/#if]
[/#macro]


[#ftl]
[#macro aws_cert_cf_genplan_segment occurrence ]
    [@addDefaultGenerationPlan subsets="template" /]
[/#macro]

[#macro aws_cert_cf_setup_segment occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

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

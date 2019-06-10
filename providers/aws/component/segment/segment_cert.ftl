[#ftl]
[#macro aws_cert_cf_segment occurrence ]
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


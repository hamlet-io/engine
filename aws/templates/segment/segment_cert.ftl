[#ftl]
[#macro aws_cert_cf_segment occurrence]
    [#return]
    [#-- Certificate --]
    [#if deploymentSubsetRequired("cert", true)]
        [#assign certificateId = formatCertificateId(segmentDomainCertificateId)]

        [@createCertificate
            mode=listMode
            id="certificate"
            domain=formatDomainName("*",segmentDomain)
            validationDomain=(domains.Validation)!""
            outputId=certificateId
        /]
    [/#if]
[/#macro]


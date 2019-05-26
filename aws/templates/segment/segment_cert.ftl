[#ftl]
[#macro segment_cert tier component]
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


[#ftl]
[#macro solution_cert tier component]
    [#-- Certificate --]

    [#if deploymentSubsetRequired("cert", true)]
        [#assign acm = component.Cert]
        [#assign certId = formatComponentCertificateId(
                            region,
                            tier,
                            component)]
        [#-- If creating cert in another region, domain must be explicitly --]
        [#-- provided                                                      --]
        [#assign certDomain = acm.Domain?has_content?then(
                                acm.Domain,
                                segmentDomain)]

        [@createCertificate
            mode=listMode
            id=certId
            domain=certDomain
            validationdomain=(domains.Validation)!""
        /]
    [/#if]
[/#macro]

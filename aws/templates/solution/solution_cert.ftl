[#-- Certificate --]
[#if componentType == "cert"]
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
        mode=solutionListMode
        id=certId
        domain=certDomain
        validationdomain=(domains.Validation)!""
    /]
[/#if]

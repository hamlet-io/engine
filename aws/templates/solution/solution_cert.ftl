[#-- Certificate --]
[#if componentType == "cert"]
    [#assign acm = component.Cert]
    [#assign certId = formatComponentCertificateId(
                        tier,
                        component)]
    [#-- If creating cert in another region, domain must be explicitly --]
    [#-- provided                                                      --]
    [#assign certDomain = acm.Domain?has_content?then(
                            acm.Domain,
                            segmentDomain)]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            "${certId}" : {
                "Type" : "AWS::CertificateManager::Certificate",
                "Properties" : {
                    "DomainName" : "${certDomain}"
                    [#if (tenantObject.Domain.Validation)??]
                        ,"DomainValidationOptions" : [
                            {
                                "DomainName" : "${certDomain}",
                                "ValidationDomain" : "${tenantObject.Domain.Validation}"
                            }
                        ]
                    [/#if]
                }
            }
            [#break]

        [#case "outputs"]
            [@output certId /]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]

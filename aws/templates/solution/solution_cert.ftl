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
    [#switch solutionListMode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
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
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output certId /]
            [#break]

    [/#switch]
[/#if]

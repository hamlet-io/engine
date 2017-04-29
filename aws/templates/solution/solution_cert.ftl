[#-- ACM Certificate --]
[#if componentType == "acm"]
    [#assign acm = component.ACM]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            "${formatId("certificate", componentIdStem)}" : {
                "Type" : "AWS::CertificateManager::Certificate",
                "Properties" : {
                    "DomainName" : "${segmentDomain}"
                    [#if (tenantObject.Domain.Validation)??]
                        ,"DomainValidationOptions" : [
                            {
                                "DomainName" : "${segmentDomain}",
                                "ValidationDomain" : "${tenantObject.Domain.Validation}"
                            }
                        ]
                    [/#if]
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId("certificate", componentIdStem)}" : {
                "Value" : { "Ref" : "${formatId("certificate", componentIdStem)}" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]

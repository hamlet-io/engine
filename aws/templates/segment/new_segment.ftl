[#-- Certificate --]
[#if deploymentSubsetRequired("cert", false)]
    [#assign wildcardCertificates = [] ]
    [#if (componentType == "apigateway")]
        [#assign apigateway = component.APIGateway]
                                         
        [#list getOccurrences(component, deploymentUnit) as occurrence]
            [#if occurrence.DNSIsConfigured  && occurrence.DNS.Enabled]
                [#assign domainObject = 
            [/#if]

        [/#list]

    [#if component
    [#assign certificateId = formatCertificateId(segmentDomainCertificateId)]
    
    [@createCertificate
        mode=listMode
        id="certificate"
        domain=formatDomainName("*",certDomain)
        validationDomain=(domains.Validation)!""
        outputId=certificateId
    /]
[/#if]


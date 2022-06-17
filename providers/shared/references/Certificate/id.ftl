[#ftl]

[@addReference
    type=CERTIFICATE_REFERENCE_TYPE
    pluralType="Certificates"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Mapping of a domain to a product certificate entry - the Id of the reference should be a product Id"
            }
        ]
    attributes=[
        {
            "Names" : "Domain",
            "Description" : "The Id of a domain reference to map to a product",
            "Types" : STRING_TYPE
        }
    ]
/]


[#function getCertificateObject start ]

    [#local certificateObject =
        getCompositeObject(
            certificateChildConfiguration,
            asFlattenedArray(
                arrayIfContent((blueprintObject.CertificateBehaviours)!{}, (blueprintObject.CertificateBehaviours)!{}) +
                arrayIfContent((tenantObject.CertificateBehaviours)!{}, (tenantObject.CertificateBehaviours)!{}) +
                arrayIfContent((productObject.CertificateBehaviours)!{}, (productObject.CertificateBehaviours)!{}) +
                ((getObjectLineage(
                    addIdNameToObjectAttributes(getReferenceData(CERTIFICATE_REFERENCE_TYPE)),
                    [productId, productName])[0])![]
                ) +
                ((getObjectLineage(
                    addIdNameToObjectAttributes(getReferenceData(CERTIFICATE_REFERENCE_TYPE)),
                    start)[0])![]
                )
            )
        )
    ]
    [#return
        certificateObject +
        {
            "Domains" : getDomainObjects(certificateObject)
        }
    ]
[/#function]

[#function getCertificateDomains certificateObject]
    [#return certificateObject.Domains![] ]
[/#function]

[#function getCertificatePrimaryDomain certificateObject]
    [#list certificateObject.Domains as domain]
        [#if isPrimaryDomain(domain) ]
            [#if !domain.Name?contains(".") ]
                [@fatal message="Missing or invalid primary domain name" context=domain /]
                [#return {} ]
            [#else]
                [#return domain ]
            [/#if]
            [#break]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#function getCertificateSecondaryDomains certificateObject]
    [#local result = [] ]
    [#list certificateObject.Domains as domain]
        [#if isSecondaryDomain(domain) ]
            [#local result += [domain] ]
            [#break]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

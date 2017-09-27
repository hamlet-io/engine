[#ftl]
[#level = "product"]
[#include "setContext.ftl" ]

[#-- Initialisation --]

[#-- Domains --]
[#assign productDomainObject = domains[productDomain]]
[#assign productDomainStem = productDomainObject.Stem]
[#assign productDomainBehaviour =
            (productDomainObject.Product)!
            (productDomainObject.ProductBehaviour)!
            ""]
[#assign productDomainValidation =
            (productDomainObject.Validation)!
            (domains.Validation)!
            ""]           
[#assign productDomainCertificateId = productDomain]
[#switch productDomainBehaviour]
    [#case "productInDomain"]
        [#assign productDomain = productName + "." + productDomainStem]
        [#assign productDomainQualifier = ""]
        [#assign productDomainCertificateId = formatName(productDomainCertificateId, productId)]
        [#break]
    [#case "naked"]
        [#assign productDomain = productDomainStem]
        [#assign productDomainQualifier = ""]
        [#break]
    [#case "productInHost"]
    [#default]
        [#assign productDomain = productDomainStem]
        [#assign productDomainQualifier = "-" + productName]
        [#break]
[/#switch]
[#assign productDomainCertificateId = productDomainCertificateId?replace("-","X")]

[#-- Product --]
[#assign rotateKeys = (productObject.RotateKeys)!true]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [@noResourcesCreated /]
        [#assign productListMode="definition"]
        [#include productList]
    },

    "Outputs" : {
        [@noResourcesCreated /]
        [#assign productListMode="outputs"]
        [#include productList]
        [@cfTemplateGlobalOutputs /]
    }
}

[#ftl]

[#-- Domains --]
[#assign productDomainStem = productObject.Domain.Stem]
[#assign productDomainBehaviour = (productObject.Domain.ProductBehaviour)!""]
[#assign productDomainCertificateId = productObject.Domain.Certificate.Id]
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
        [#assign resourceCount = 0]
        [#assign productListMode="definition"]
        [#include productList]
    },

    "Outputs" : {
        [#assign resourceCount = 0]
        [#assign productListMode="outputs"]
        [#include productList]
    }
}

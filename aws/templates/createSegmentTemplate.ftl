[#ftl]
[#include "setContext.ftl" ]

[#-- Domains --]
[#assign productDomainStem = productObject.Domain.Stem]
[#assign segmentDomainBehaviour = (productObject.Domain.SegmentBehaviour)!""]
[#assign segmentDomainCertificateId = productObject.Domain.Certificate.Id]
[#switch segmentDomainBehaviour]
    [#case "segmentProductInDomain"]
        [#assign segmentDomain = segmentName + "." + productName + "." + productDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#assign segmentDomainCertificateId = formatName(segmentDomainCertificateId, productId, + segmentId)]
        [#break]
    [#case "segmentInDomain"]
        [#assign segmentDomain = segmentName + "." + productDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#assign segmentDomainCertificateId = formatName(segmentDomainCertificateId, segmentId)]
        [#break]
    [#case "naked"]
        [#assign segmentDomain = productDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#break]
    [#case "segmentInHost"]
        [#assign segmentDomain = productDomainStem]
        [#assign segmentDomainQualifier = "-" + segmentName]
        [#break]
    [#case "segmentProductInHost"]
    [#default]
        [#assign segmentDomain = productDomainStem]
        [#assign segmentDomainQualifier = "-" + formatName(segmentName, productName)]
        [#break]
[/#switch]
[#assign segmentDomainCertificateId = segmentDomainCertificateId?replace("-","X")]

[#-- Bucket names - may already exist --]
[#if operationsBucket == "unknown"]
    [#assign operationsBucket = operationsBucketType + segmentDomainQualifier + "." + segmentDomain]
[/#if]
[#if dataBucket == "unknown"]
    [#assign dataBucket = dataBucketType + segmentDomainQualifier + "." + segmentDomain]
[/#if]


[#assign operationsExpiration = (segmentObject.Operations.Expiration)!(environmentObject.Operations.Expiration)!"none"]
[#assign dataExpiration = (segmentObject.Data.Expiration)!(environmentObject.Data.Expiration)!"none"]

[#-- Segment --]
[#assign baseAddress = segmentObject.CIDR.Address?split(".")]
[#assign addressOffset = baseAddress[2]?number*256 + baseAddress[3]?number]
[#assign addressesPerTier = powersOf2[getPowerOf2(powersOf2[32 - segmentObject.CIDR.Mask]/(segmentObject.Tiers.Order?size))]]
[#assign addressesPerZone = powersOf2[getPowerOf2(addressesPerTier / (segmentObject.Zones.Order?size))]]
[#assign subnetMask = 32 - powersOf2?seq_index_of(addressesPerZone)]
[#assign dnsSupport = segmentObject.DNSSupport]
[#assign dnsHostnames = segmentObject.DNSHostnames]
[#assign rotateKeys = (segmentObject.RotateKeys)!true]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl" ],
    "Resources" : {
        [#assign resourceCount = 0]
        [#assign segmentListMode="definition"]
        [#include segmentList]                      
    },
    "Outputs" : 
    {
        [#assign resourceCount = 0]
        [#assign segmentListMode="outputs"]
        [#include segmentList]
    }
}



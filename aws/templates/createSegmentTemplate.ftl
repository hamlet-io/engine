[#ftl]
[#include "setContext.ftl" ]

[#-- Functions --]

[#-- Macros --]

[#macro createVPCFlowLog mode id vpcId roleId logGroupName trafficType]
    [@createFlowLog 
        mode,
        id,
        roleId,
        logGroupName,
        vpcId,
        "VPC",
        trafficType /]
[/#macro]

[#macro createVPCLogGroup mode id name retention ]
    [#if isPartOfCurrentDeploymentUnit(id)]
        [@createLogGroup 
            mode
            id
            name
            retention /]
    [/#if]
[/#macro]

[#-- Initialisation --]

[#-- Domains --]
[#assign segmentDomainId = segmentObject.Domain!productDomain]
[#assign segmentDomainObject = domains[segmentDomainId]]
[#assign segmentDomainStem = segmentDomainObject.Stem]
[#assign segmentDomainBehaviour =
            (segmentDomainObject.Segment)!
            (segmentDomainObject.SegmentBehaviour)!
            (environmentObject.DomainBehaviours.Segment)!
            ""]
[#assign segmentDomainValidation =
            (segmentDomainObject.Validation)!
            (domains.Validation)!
            ""]           
[#assign segmentDomainCertificateId = segmentDomainId]
[#switch segmentDomainBehaviour]
    [#case "segmentProductInDomain"]
        [#assign segmentDomain = segmentName + "." + productName + "." + segmentDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#assign segmentDomainCertificateId = formatName(segmentDomainCertificateId, productId, segmentId)]
        [#break]
    [#case "segmentInDomain"]
        [#assign segmentDomain = segmentName + "." + segmentDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#assign segmentDomainCertificateId = formatName(segmentDomainCertificateId, segmentId)]
        [#break]
    [#case "naked"]
        [#assign segmentDomain = segmentDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#break]
    [#case "segmentInHost"]
        [#assign segmentDomain = segmentDomainStem]
        [#assign segmentDomainQualifier = segmentName]
        [#break]
    [#case "segmentProductInHost"]
    [#default]
        [#assign segmentDomain = segmentDomainStem]
        [#assign segmentDomainQualifier = formatName(segmentName, productName)]
        [#break]
[/#switch]
[#assign segmentDomainCertificateId = segmentDomainCertificateId?replace("-","X")]

[#-- Bucket names - may already exist --]
[#if operationsBucket == "unknown"]
    [#assign operationsBucket = formatName(operationsBucketType, segmentDomainQualifier) + "." + segmentDomain]
[/#if]
[#if dataBucket == "unknown"]
    [#assign dataBucket = formatName(dataBucketType, segmentDomainQualifier) + "." + segmentDomain]
[/#if]

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
        [@noResourcesCreated /]
        [#assign segmentListMode="definition"]
        [#include segmentList]                      
    },
    "Outputs" : 
    {
        [@noResourcesCreated /]
        [#assign segmentListMode="outputs"]
        [#include segmentList]
    }
}



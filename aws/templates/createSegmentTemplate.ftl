[#ftl]
[#include "setContext.ftl" ]

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


[#-- Special processing --]
[#switch deploymentUnit]
    [#case "eip"]
    [#case "iam"]
    [#case "lg"]
        [#assign allDeploymentUnits = true]
        [#assign deploymentUnitSubset = deploymentUnit]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [#break]
[/#switch]

[@cfTemplate
    level="segment"
    compositeLists=segmentList /]



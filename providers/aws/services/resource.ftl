[#ftl]

[#-- Format an ARN --]
[#function formatTypedArnResource resourceType resource resourceSeparator=":" subresources=[] ]
    [#return
        {
            "Fn::Join": [
                resourceSeparator,
                [
                    resourceType,
                    resource
                ] +
                subresources
            ]
        }
    ]
    [#return resourceType + resourceSeparator + resource]
[/#function]

[#function formatArn partition service region account resource asString=false]
    [#if asString ]
        [#return
            [
                "arn",
                partition,
                service,
                region,
                account,
                resource
            ]?join(":")
        ]
    [#else]
        [#return
            {
                "Fn::Join": [
                    ":",
                    [
                        "arn",
                        partition,
                        service,
                        region,
                        account,
                        resource
                    ]
                ]
            }
        ]
    [/#if]
[/#function]

[#function getArn idOrArn existingOnly=false inRegion=""]
    [#if idOrArn?is_hash || idOrArn?contains(":")]
        [#return idOrArn]
    [#else]
        [#return
            valueIfTrue(
                getExistingReference(idOrArn, ARN_ATTRIBUTE_TYPE, inRegion),
                existingOnly,
                getReference(idOrArn, ARN_ATTRIBUTE_TYPE, inRegion)
            ) ]
    [/#if]
[/#function]

[#function formatRegionalArn service resource region={ "Ref" : "AWS::Region" } account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatArn(
            { "Ref" : "AWS::Partition" },
            service,
            region,
            account,
            resource
        )
    ]
[/#function]

[#function formatGlobalArn service resource account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatRegionalArn(
            service,
            resource,
            "",
            account
        )
    ]
[/#function]

[#-- Metric Dimensions are extended dynamically by each resouce type --]
[#assign metricAttributes = {
    "_none" : {
        "Namespace" : "",
        "Dimensions" : {
            "None" : {
                "None" : ""
            }
        }
    }
}]

[#-- Include a reference to a resource --]
[#-- Allows resources to share a template or be separated --]
[#-- Note that if separate, creation order becomes important --]
[#function getExistingReference resourceId attributeType="" inRegion="" inDeploymentUnit="" inAccount=(accountObject.AWSId)!""]
    [#local attributeType = (attributeType == REFERENCE_ATTRIBUTE_TYPE)?then(
                                "",
                                attributeType
    )]
    [#return getStackOutput( AWS_PROVIDER, formatAttributeId(resourceId, attributeType), inDeploymentUnit, inRegion, inAccount) ]
[/#function]

[#function migrateToResourceId resourceId legacyIds=[] inRegion="" inDeploymentUnit="" inAccount=(accountObject.AWSId)!""]

    [#list asArray(legacyIds) as legacyId]
        [#if getExistingReference(legacyId, "", inRegion, inDeploymentUnit, inAccount)?has_content]
            [#return legacyId]
        [/#if]
    [/#list]
    [#return resourceId]
[/#function]

[#function getReference resourceId attributeType="" inRegion=""]
    [#if !(resourceId?has_content)]
        [#return ""]
    [/#if]
    [#if resourceId?is_hash]
        [#return
            {
                "Ref" : value.Ref
            }
        ]
    [/#if]
    [#if ((!(inRegion?has_content)) || (inRegion == region)) &&
        isPartOfCurrentDeploymentUnit(resourceId)]
        [#if attributeType?has_content]
            [#local resourceType = getResourceType(resourceId) ]
            [#local mapping = getOutputMappings(AWS_PROVIDER, resourceType, attributeType)]
            [#if (mapping.Attribute)?has_content]
                [#return
                    {
                        "Fn::GetAtt" : [resourceId, mapping.Attribute]
                    }
                ]
            [#elseif !(mapping.UseRef)!false ]
                [#return
                    {
                        "Mapping" : "COTFatal: Unknown Resource Type",
                        "ResourceId" : resourceId,
                        "ResourceType" : resourceType
                    }
                ]
            [/#if]
        [/#if]
        [#return
            {
                "Ref" : resourceId
            }
        ]
    [/#if]
    [#return
        getExistingReference(
            resourceId,
            attributeType,
            inRegion)
    ]
[/#function]

[#function getReferences resourceIds attributeType="" inRegion=""]
    [#local result = [] ]
    [#list asArray(resourceIds) as resourceId]
        [#local result += [getReference(resourceId, attributeType, inRegion)] ]
    [/#list]
    [#return result]
[/#function]

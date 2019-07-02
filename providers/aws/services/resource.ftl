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

[#-- Get stack output --]
[#function getStackOutputObject id deploymentUnit="" region="" account=(accountObject.AWSId)!""]
    [#list stackOutputsList as stackOutputs]
        [#local outputId = stackOutputs[id]?has_content?then(
                id,
                formatId(id, stackOutputs.Region?replace("-", "X"))
            )
        ]

        [#if
            ((!account?has_content)||(account == stackOutputs.Account)) &&
            ((!region?has_content)||(region == stackOutputs.Region)) &&
            ((!deploymentUnit?has_content)||(deploymentUnit == stackOutputs.DeploymentUnit)) &&
            (stackOutputs[outputId]?has_content)
        ]
            [#return
                {
                    "Account" : stackOutputs.Account,
                    "Region" : stackOutputs.Region,
                    "Level" : stackOutputs.Level,
                    "DeploymentUnit" : stackOutputs.DeploymentUnit,
                    "Id" : id,
                    "Value" : stackOutputs[outputId]
                }
            ]
        [/#if]
    [/#list]
    [#return {}]
[/#function]

[#function getStackOutput id deploymentUnit="" region="" account=(accountObject.AWSId)!""]
    [#local result =
        getStackOutputObject(
            id,
            deploymentUnit,
            region,
            account
        )
    ]
    [#return
        result?has_content?then(
            result.Value,
            ""
        )
    ]
[/#function]

[#-- Is a resource part of a deployment unit --]
[#function isPartOfDeploymentUnit resourceId deploymentUnit deploymentUnitSubset]
    [#local resourceObject = getStackOutputObject(resourceId)]
    [#local
        currentDeploymentUnit =
            deploymentUnit +
            deploymentUnitSubset?has_content?then(
                "-" + deploymentUnitSubset?lower_case,
                ""
            )
    ]
    [#return !(resourceObject?has_content &&
                (resourceObject.DeploymentUnit != currentDeploymentUnit))]
[/#function]

[#-- Is a resource part of the current deployment unit --]
[#function isPartOfCurrentDeploymentUnit resourceId]
    [#return
        isPartOfDeploymentUnit(
            resourceId,
            deploymentUnit,
            (ignoreDeploymentUnitSubsetInOutputs!false)?then(
                "",
                deploymentUnitSubset!""
            )
        )]
[/#function]

[#-- Output mappings object is extended dynamically by each resource type --]
[#assign outputMappings = {} ]

[#-- Metric Dimensions are extended dynamically by each resouce type --]
[#assign metricAttributes = {}]

[#-- Include a reference to a resource --]
[#-- Allows resources to share a template or be separated --]
[#-- Note that if separate, creation order becomes important --]
[#function getExistingReference resourceId attributeType="" inRegion="" inDeploymentUnit="" inAccount=(accountObject.AWSId)!""]
    [#return getStackOutput(formatAttributeId(resourceId, attributeType), inDeploymentUnit, inRegion, inAccount) ]
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
            [#if outputMappings[resourceType]?? ]
                [#local mapping = outputMappings[getResourceType(resourceId)][attributeType] ]
                [#if (mapping.Attribute)?has_content]
                    [#return
                        {
                            "Fn::GetAtt" : [resourceId, mapping.Attribute]
                        }
                    ]
                [/#if]
            [#else]
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

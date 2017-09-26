[#ftl]

[#-- Format an ARN --]
[#function formatTypedArnResource resourceType resource resourceSeparator=":"]
    [#return
        { 
            "Fn::Join": [
                resourceSeparator, 
                [
                    resourceType,
                    resource
                ]
            ]
        }
    ]
    [#return resourceType + resourceSeparator + resource]
[/#function]

[#function formatArn partition service region account resource]
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
[#function getStackOutputObject id deploymentUnit="" region="" account=""]
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

[#function getStackOutput id deploymentUnit="" region="" account=""]
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

[#-- Include a reference to a resource --]
[#-- Allows resources to share a template or be separated --]
[#-- Note that if separate, creation order becomes important --]
[#function getExistingReference resourceId attributeType="" inRegion="" inDeploymentUnit="" inAccount=""]
    [#return getStackOutput(formatAttributeId(resourceId, attributeType), inDeploymentUnit, inRegion, inAccount) ]
[/#function]

[#function migrateToResourceId resourceId legacyIds=[] inRegion="" inDeploymentUnit="" inAccount=""]

    [#list asArray(legacyIds) as legacyId]
        [#if getExistingReference(legacyId, "", inRegion, inDeploymentUnit, inAccount)?has_content]
            [#return legacyId]
        [/#if]
    [/#list]
    [#return resourceId]
[/#function]

[#function getReference resourceId attributeType="" inRegion=""]
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
            [#local mapping = outputMappings[getResourceType(resourceId)][attributeType] ]
            [#if (mapping.Attribute)?has_content]
                [#return
                    {
                        "Fn::GetAtt" : [resourceId, mapping.Attribute] 
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

[#macro noResourcesCreated]
    [#assign resourceCount = 0]
[/#macro]

[#macro resourcesCreated count=1]
    [#assign resourceCount += count]
[/#macro]

[#macro checkIfResourcesCreated]
    [#if resourceCount > 0],[/#if]
[/#macro]

[#function getCfTemplateCoreTags name="" tier="" component="" zone="" propagate=false]
    [#local result = 
        [
            { "Key" : "cot:request", "Value" : requestReference }
        ] +
        accountObject.CostCentre?has_content?then(
            [
                { "Key" : "cot:costcentre", "Value" : accountObject.CostCentre }
            ],
            []
        ) +
        [
            { "Key" : "cot:configuration", "Value" : configurationReference },
            { "Key" : "cot:tenant", "Value" : tenantId },
            { "Key" : "cot:account", "Value" : accountId }
        ] +
        productId?has_content?then(
            [
                { "Key" : "cot:product", "Value" : productId }
            ],
            []
        ) +
        segmentId?has_content?then(
            [
                { "Key" : "cot:segment", "Value" : segmentId }
            ],
            []
        ) +
        environmentId?has_content?then(
            [
                { "Key" : "cot:environment", "Value" : environmentId }
            ],
            []
        ) +
        [
            { "Key" : "cot:category", "Value" : categoryId }
        ] +
        tier?has_content?then(
            [
                { "Key" : "cot:tier", "Value" : getTierId(tier) }
            ],
            []
        ) +
        component?has_content?then(
            [
                { "Key" : "cot:component", "Value" : getComponentId(component) }
            ],
            []
        ) +
        zone?has_content?then(
            [
                { "Key" : "cot:zone", "Value" : getZoneId(zone) }
            ],
            []
        ) + 
        name?has_content?then(
            [
                { "Key" : "Name", "Value" : name }
            ],
            []
        )
    ]
    [#if propagate]
        [#local returnValue = []]
        [#list result as entry]
            [#local returnValue +=
                [
                    entry + {"PropagateAtLaunch" : "True" }
                ]
            ]
        [/#list]
        [#return returnValue]
    [#else]
        [#return result]
    [/#if]
[/#function]

[#function getCfTemplateDefaultOutputs]
    [#return
        {
            REFERENCE_ATTRIBUTE_TYPE : {
                "UseRef" : true
            }
        }
    ]
[/#function]

[#macro cfTemplateOutput mode id value]
    [#switch mode]
        [#case "outputs"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Value" : [@toJSON value /]
            }
            [@resourcesCreated /]
            [#break]
    [/#switch]
[/#macro]

[#macro cfTemplateGlobalOutputs mode level]
    [@cfTemplateOutput mode "Account" { "Ref" : "AWS::AccountId" } /]
    [@cfTemplateOutput mode "Region" { "Ref" : "AWS::Region" } /]
    [@cfTemplateOutput mode "Level" level /]
    [@cfTemplateOutput mode "DeploymentUnit"
                        deploymentUnit + 
                        (
                            (!(ignoreDeploymentUnitSubsetInOutputs!false)) &&
                            (deploymentUnitSubset?has_content)
                        )?then(
                            "-" + deploymentUnitSubset?lower_case,
                            ""
                        ) /]
[/#macro]

[#macro cfTemplate
            mode
            id 
            type 
            properties={}
            tags=[]
            outputs=getCfTemplateDefaultOutputs()
            outputId=""
            dependencies=[]
            metadata={}
            deletionPolicy=""]

    [#local localDependencies = [] ]
    [#list asArray(dependencies) as resourceId]
        [#if getReference(resourceId)?is_hash]
            [#local localDependencies += [resourceId] ]
        [/#if]
    [/#list]

    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}": {
                "Type" : "${type}"
                [#if metadata?has_content]
                    ,"Metadata" : [@toJSON metadata /]
                [/#if]
                [#if properties?has_content || tags?has_content]
                    ,"Properties" : {
                        [#list properties as key,value]
                            "${key}" : [@toJSON value /]
                            [#sep],[/#sep]
                        [/#list]
                        [#if tags?has_content]
                            [#if properties?has_content],[/#if]
                            "Tags" : [@toJSON tags /]
                        [/#if]
                    }
                [/#if]
                [#if localDependencies?has_content]
                    ,"DependsOn" : [@toJSON localDependencies /]
                [/#if]
                [#if deletionPolicy?has_content]
                    ,"DeletionPolicy" : [@toJSON deletionPolicy /]
                [/#if]
            }
            [@resourcesCreated /]        
            [#break]

        [#case "outputs"]
            [#assign oId = outputId?has_content?then(outputId, id)]
            [#list outputs as type,value]
                [#if type == REFERENCE_ATTRIBUTE_TYPE]
                    [@cfTemplateOutput
                        mode,
                        oId,
                        {
                            "Ref" : id
                        }
                    /]
                [#else]
                    [@cfTemplateOutput
                        mode,
                        formatAttributeId(oId, type),
                        ((value.UseRef)!false)?then(
                            {
                                "Ref" : id
                            },
                            value.Value?has_content?then(
                                value.Value,
                                {
                                    "Fn::GetAtt" : [id, value.Attribute] 
                                }
                            )
                        )                                    
                    /]
                [/#if]
            [/#list]
            [#break]

    [/#switch]
[/#macro]

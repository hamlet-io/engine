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
                        "Mapping" : "ERROR_UNKNOWN_RESOURCE_TYPE",
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

[#macro cfOutput mode id value resourceId=""]
    [#switch mode]
        [#case "outputs"]
            [#local output =
                {
                    id : { "Value" : value }
                }
            ]
            [#assign templateOutputs += output]
            [#if resourceId?has_content && componentTemplates??]
                [#local resourceOutputs = (componentTemplates[resourceId].Outputs)!{}]
                [#assign componentTemplates +=
                    {
                        resourceId : 
                            ((componentTemplates[resourceId])!{}) +
                            {
                                "Outputs" : resourceOutputs + output
                            }
                    }
                ]
            [/#if]
            [#break]
    [/#switch]
[/#macro]

[#macro cfResource
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
            [#local definition =
                {
                    id : 
                        {
                            "Type" : type
                        } +
                        attributeIfContent("Metadata", metadata) +
                        attributeIfTrue(
                            "Properties",
                            properties?has_content || tags?has_content,
                            properties + attributeIfContent("Tags", tags)) +
                        attributeIfContent("DependsOn", localDependencies) + 
                        attributeIfContent("DeletionPolicy", deletionPolicy)
                }
            ]
            [#assign templateResources += definition]
            [#if componentTemplates??]
                [#assign componentTemplates +=
                    {
                        id : 
                            ((componentTemplates[id])!{}) +
                            {
                                "Definition" : definition
                            }
                    }
                ]
            [/#if]
            [#break]

        [#case "outputs"]
            [#assign oId = outputId?has_content?then(outputId, id)]
            [#list outputs as type,value]
                [#if type == REFERENCE_ATTRIBUTE_TYPE]
                    [@cfOutput
                        mode,
                        oId,
                        {
                            "Ref" : id
                        },
                        id
                    /]
                [#else]
                    [@cfOutput
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
                        ),
                        id
                    /]
                [/#if]
            [/#list]
            [#break]

    [/#switch]
[/#macro]

[#macro cfConfig
            mode
            content={}]

    [#switch mode]
        [#case "config"]
            [#assign templateConfig += content]
            [#break]

    [/#switch]
[/#macro]

[#macro cfScript
            mode
            content=[]]

    [#switch mode]
        [#case "script"]
            [#assign templateScript += content]
            [#break]

    [/#switch]
[/#macro]

[#macro cfDebug
            mode
            value
            enabled=true]

    [#switch mode]
        [#case "definition"]
            [#if enabled]
                [#assign debugResources += [value] ]
            [/#if]
            [#break]

    [/#switch]
[/#macro]

[#macro cfException
            mode
            description
            context={}
            detail=""]

    [#switch mode]
        [#case "definition"]
            [#assign exceptionResources +=
                [
                    {
                        "Description" : description,
                        "Context" : context
                    } + 
                    valueIfContent(
                        {
                            "Detail" : detail
                        },
                        detail
                    )
                ]
            ]
            [#break]

    [/#switch]
[/#macro]

[#macro cfPreconditionFailed
            mode
            function
            context={}
            description=""]

    [#switch mode]
        [#case "definition"]
            [@cfException
                mode
                function + " precondition failed"
                context
                description /]
            [#break]

    [/#switch]
[/#macro]

[#macro cfPostconditionFailed
            mode
            function
            context={}
            description=""]

    [#switch mode]
        [#case "definition"]
            [@cfException
                mode
                function + " postcondition failed"
                context
                description /]
            [#break]

    [/#switch]
[/#macro]

[#macro includeCompositeLists compositeLists=[] ]
    [#list tiers as tier]
        [#assign tierId = tier.Id]
        [#assign tierName = tier.Name]
        [#if tier.Components??]
            [#list tier.Components?values as component]
                [#if deploymentRequired(component, deploymentUnit)]
                    [#assign componentTemplates = {} ]
                    [#assign componentId = getComponentId(component)]
                    [#assign componentName = getComponentName(component)]
                    [#assign componentType = getComponentType(component)]
                    [#assign componentIdStem = formatComponentId(tier, component)]
                    [#assign componentShortName = formatComponentShortName(tier, component)]
                    [#assign componentShortNameWithType = formatComponentShortNameWithType(tier, component)]
                    [#assign componentShortFullName = formatComponentShortFullName(tier, component)]
                    [#assign componentFullName = formatComponentFullName(tier, component)]
                    [#assign dashboardRows = []]
                    [#assign multiAZ = component.MultiAZ!solnMultiAZ]
                    [#list asArray(compositeLists) as compositeList]
                        [#include compositeList?ensure_starts_with("/")]
                    [/#list]
                    [#if dashboardRows?has_content]
                        [#assign dashboardComponents += [
                                {
                                    "Title" : component.Title?has_content?then(
                                                component.Title,
                                                formatComponentName(tier, component)),
                                    "Rows" : dashboardRows
                                }
                            ]
                        ]
                    [/#if]
                [/#if]
            [/#list]
        [/#if]
    [/#list]
[/#macro]

[#macro cfTemplate level include="" compositeLists=[]]
    
    [#-- Resources --]
    [#assign templateResources = {} ]
    [#assign debugResources = [] ]
    [#assign exceptionResources = [] ]
    [#assign listMode = "definition"]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@includeCompositeLists asArray(compositeLists) /]
    [/#if]

    [#-- Outputs --]
    [#assign templateOutputs={} ]
    [#assign listMode="outputs"]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@includeCompositeLists asArray(compositeLists) /]
    [/#if]

    [#-- Config --]
    [#assign templateConfig = {} ]
    [#assign listMode="config"]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@includeCompositeLists asArray(compositeLists) /]
    [/#if]

    [#-- Script --]
    [#assign templateScript = [] ]
    [#assign listMode="script"]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@includeCompositeLists asArray(compositeLists) /]
    [/#if]

    [#if templateResources?has_content]
      [@toJSON
          {
              "AWSTemplateFormatVersion" : "2010-09-09",
              "Metadata" :
                  {
                      "Prepared" : .now?iso_utc,
                      "RequestReference" : requestReference,
                      "ConfigurationReference" : configurationReference
                  } +
                  attributeIfContent("CostCentre", accountObject.CostCentre!"") +
                  attributeIfContent("BuildReference", buildCommit!"") +
                  attributeIfContent("AppReference", appReference!""),
              "Resources" : templateResources,
              "Outputs" :
                  templateOutputs +
                  {
                      "Account" :{"Value" : { "Ref" : "AWS::AccountId" }},
                      "Region" : {"Value" : { "Ref" : "AWS::Region" }},
                      "Level" : {"Value" : level},
                      "DeploymentUnit" : 
                          {
                              "Value" :
                                  deploymentUnit + 
                                  (
                                      (!(ignoreDeploymentUnitSubsetInOutputs!false)) &&
                                      (deploymentUnitSubset?has_content)
                                  )?then(
                                      "-" + deploymentUnitSubset?lower_case,
                                      ""
                                  )
                          }
                  }
          } +
          valueIfContent(
              {
                  "Debug" : debugResources
              },
              debugResources
          ) +
          valueIfContent(
              {
                  "Exceptions" : exceptionResources
              },
              exceptionResources
          )
      /]
    [#elseif templateScript?has_content]
      #!/bin/bash
      [#list templateScript as line]
          ${line}       
      [/#list]
    [#elseif templateConfig?has_content]
        [@toJSON templateConfig /]
    [/#if]
[/#macro]

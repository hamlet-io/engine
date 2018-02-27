[#ftl]
[#include "setContext.ftl" ]

[#assign listMode = "blueprint"]
[#assign allDeploymentUnits = true]
[#assign deploymentUnit = ""]

[#function getIntegratorBlueprint]
  [#local result= {
      "Id": tenantObject.Id,
      "Title" : tenantObject.Title!productObject.Id,
      "Products" : getTenantBlueprint() 
    } ]
  [#return result ]
[/#function]

[#function getTenantBlueprint]
  [#local result= [
      { 
        "Id" : productObject.Id,
        "Title" : productObject.Title!productObject.Id,
        "Environments" : getProductBlueprint() 
      } ]]
  [#return result ]
[/#function]

[#function getProductBlueprint ]
  [#local result= [
      { 
        "Id" : environmentId,
        "Name" : environmentObject.Name,
        "Segments" : getEnvironmentBlueprint() 
      } ]]
  [#return result ]
[/#function]

[#function getEnvironmentBlueprint ]
  [#local result=[  
      {
        "Id" :segmentId,
        "Tiers" : getSegmentBlueprint() 
      } ]]
  [#return result ]
[/#function]

[#function getSegmentBlueprint ]
  [#local result=[] ]
  [#list tiers as tier]
    [#assign tierId = tier.Id]
    [#assign tierName = tier.Name]
    [#local result += [ 
        {
            "Id" : tierId,
            "Components" :  getTierBlueprint(tier)
        }] ]
  [/#list]
  [#return result ]
[/#function]

[#function getTierBlueprint tier]
  [#local result=[] ]
  [#list tier.Components!{} as id,component]
    [#if component?is_hash]
      [#assign componentTemplates = {} ]
      [#assign componentId = getComponentId(component)]
      [#assign componentName = getComponentName(component)]
      [#assign componentType = getComponentType(component)]
      [#assign componentIdStem = formatComponentId(tier, component)]
      [#assign componentShortName = formatComponentShortName(tier, component)]
      [#assign componentShortNameWithType = formatComponentShortNameWithType(tier, component)]
      [#assign componentShortFullName = formatComponentShortFullName(tier, component)]
      [#assign componentFullName = formatComponentFullName(tier, component)]

      [#local result +=
        [
          {
            "Id": id,
            "Occurrences" : getOccurrences(component, tier, component)
            }
        ] ]
    [/#if]
  [/#list]
  [#return  result ]
[/#function]

[#if deploymentSubsetRequired("blueprint", true)]
  [@toJSON getIntegratorBlueprint() /]
[/#if]




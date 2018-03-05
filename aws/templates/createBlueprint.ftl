[#ftl]
[#include "setContext.ftl" ]

[#assign listMode = "blueprint"]
[#assign allDeploymentUnits = true]
[#assign deploymentUnit = ""]

[#function getTenantBlueprint]
  [#local result=
  {
    "Tenants" : [
      {
        "Id" : tenantObject.Id,
        "Configuration" : tenantObject,
        "Domains" : domains,
        "Products" : getProductBlueprint() 
      } 
    ]
  }]
  [#return result ]
[/#function]

[#function getProductBlueprint]
  [#local result= [
      { 
        "Id" : productObject.Id,
        "Configuration" : productObject,
        "Environments" : getEnvironmentBlueprint()  
      } 
    ]] 
    [#return result ]
[/#function]

[#function getEnvironmentBlueprint]
  [#local result= [
      {
        "Id" : environmentObject.Id,
        "Configuration" : environmentObject,
        "Solutions" : getSolutionBlueprint()
      }
  ]]
  [#return result ]
[/#function]

[#function getSolutionBlueprint]
  [#local result= [
      {
        "Id" : solutionObject.Id,
        "Configuration" : solutionObject,
        "Segments" : getSegmentBlueprint()
      }
    ]]
    [#return result ]
[/#function]

[#function getSegmentBlueprint ]
  [#local result=[
      {
        "Id" : segmentObject.Id,
        "Configuration" : segmentObject,
        "Account" : accountObject,
        "Tiers" : getTierBlueprint() 
      } 
    ]]
  [#return result ]
[/#function]

[#function getTierBlueprint ]
  [#local result=[] ]
  [#list tiers as tier]
    [#local result += [ 
        {
            "Id" : tier.Id,
            "Configuration" : {
              "Description": tier.Description,
              "Network": tier.Network.Enabled,
              "NetworkACL": tier.Network.NetworkACL,
              "RouteTable": tier.Network.RouteTable,
              "Title": tier.Title,
              "Id": tier.Id,
              "Name": tier.Name
            },
            "Components" :  getComponentBlueprint(tier)
        }]]
  [/#list]
  [#return result ]
[/#function]

[#function getComponentBlueprint tier]
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
              "Id" : id,
              "Occurrences" : getOccurrences(tier, component)
          }]]
    [/#if]
  [/#list]
  [#return  result ]
[/#function]

[#if deploymentSubsetRequired("blueprint", true)]
  [@toJSON getTenantBlueprint() /]
[/#if]




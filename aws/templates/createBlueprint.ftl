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
        tenantObject.Id : {
          "Configuration" : tenantObject,
          "Domains" : domains,
          "Products" : getProductBlueprint() 
        } 
      }
    ]
  }]
  [#return result ]
[/#function]

[#function getProductBlueprint]
  [#local result= [
    {
      productObject.Id : { 
        "Configuration" : productObject,
        "Environments" : getEnvironmentBlueprint()  
      } 
    }]] 
    [#return result ]
[/#function]

[#function getEnvironmentBlueprint]
  [#local result= [
    {
      environmentObject.Id : {
        "Configuration" : environmentObject,
        "Solutions" : getSolutionBlueprint()
      }
    }
  ]]
  [#return result ]
[/#function]

[#function getSolutionBlueprint]
  [#local result= [
    {
      solutionObject.Id : {
        "Configuration" : solutionObject,
        "Segments" : getSegmentBlueprint()
      }
    }]]
    [#return result ]
[/#function]

[#function getSegmentBlueprint ]
  [#local result=[
    {
      segmentObject.Id : {
        "Configuration" : segmentObject,
        "Account" : accountObject,
        "Tiers" : getTierBlueprint() 
      } 
    }]]
  [#return result ]
[/#function]

[#function getTierBlueprint ]
  [#local result=[] ]
  [#list tiers as tier]
    [#local result += [ 
      {
        tier.Id : {
            "Configuration" : {
              "Description": tier.Description,
              "NetworkACL": tier.NetworkACL,
              "RouteTable": tier.RouteTable,
              "Title": tier.Title,
              "Id": tier.Id,
              "Name": tier.Name
            },
            "Components" :  getComponentBlueprint(tier)
        }
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
            id : {
              "Occurrences" : getOccurrences(component, tier, component)
              }
          }
        ] ]
    [/#if]
  [/#list]
  [#return  result ]
[/#function]

[#if deploymentSubsetRequired("blueprint", true)]
  [@toJSON getTenantBlueprint() /]
[/#if]




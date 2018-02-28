[#ftl]
[#include "setContext.ftl" ]

[#assign listMode = "blueprint"]
[#assign allDeploymentUnits = true]
[#assign deploymentUnit = ""]

[#function getIntegratorBlueprint]
  [#local result=
  {
    "Tenants" : [
      {
        tenantObject.Id : {
          "Configuration" : tenantObject,
          "Domains" : domains,
          "Products" : getTenantBlueprint() 
        } 
      }
    ]
  }]
  [#return result ]
[/#function]

[#function getTenantBlueprint]
  [#local result= [
    {
      productObject.Id : { 
        "Configuration" : productObject,
        "Solutions" : getProductBluePrint()  
      } 
    }]] 
  [#return result ]
[/#function]

[#function getProductBluePrint ]
  [#local result = [
      {
        solutionObject.Id : { 
          "Configuration": solutionObject,
          "Segments" : getEnvironmentBlueprint()
        }
      } 
  ]]
  [#return result]
[/#function]

[#function getEnvironmentBlueprint ]
  [#local result=[
    {
      segmentObject.Id : {
        "Configuration" : segmentObject,
        "Environment" : environmentObject,
        "Account" : accountObject,
        "Tiers" : getSegmentBlueprint() 
      } 
    }]]
  [#return result ]
[/#function]

[#function getSegmentBlueprint ]
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
            "Components" :  getTierBlueprint(tier)
        }
        }]]
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
  [@toJSON getIntegratorBlueprint() /]
[/#if]




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
        "Solution" : solutionObject,
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

      [#-- Only include deployed Occurrences --]
      [#local occurrences = getOccurrences(tier, component) ]
      [#local deployedOccurrences = [] ]

      [#list getOccurrences(tier, component) as occurrence ]
        [#list occurrence.State.Resources?values as resource ]
          [#if resource.Deployed ]
            [#local deployedOccurrences += [ occurrence ]]
            [#continue]
          [/#if]
        [/#list]
      [/#list]

      [#local cleanedOccurrences = []]
      [#list deployedOccurrences as occurrence ] 
        [#list occurrence.State.Attributes as key, value ]
          [#if key?lower_case == "password" || key?lower_case?contains("key") ]
              [#local cleanAttributes += 
                {
                  key : "***"
                }
              ]
            [#else]
              [#local cleanAttributes += 
                {
                  key : value
                }
              ]
          [/#if]
        [/#list]
      [/#list]

      [#local result +=
        [
          {
            "Id" : id,
            "Occurrences" : cleanedOccurrences
        }]]
    [/#if]
  [/#list]
  [#return  result ]
[/#function]

[#if deploymentSubsetRequired("blueprint", true)]
  [@toJSON getTenantBlueprint() /]
[/#if]




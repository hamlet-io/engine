[#ftl]
[#include "setContext.ftl" ]

[#assign listMode = "blueprint"]
[#assign allDeploymentUnits = true]
[#assign deploymentUnit = ""]

[#function getCleanedAttributes attributes ]
  [#local result={} ] 
  [#list attributes as key, value]
    [#local result += 
      valueIfTrue(
        { key : "***" },
        key?lower_case?contains("password") || key?lower_case?contains("key"),
        { key: value } ) ]      
  [/#list]
  [#return result]
[/#function]

[#function getCleanedOccurrence occurrence ] 
  [#return 
    occurrence + { "State" : occurrence.State + { "Attributes" : getCleanedAttributes(occurrence.State.Attributes) } } ]
[/#function]

[#function getTenantBlueprint]
  [#local result=
  {
    "Metadata" : {
      "Prepared" : .now?iso_utc,
      "RequestReference" : requestReference,
      "ConfigurationReference" : configurationReference,
      "RunId" : runId
    },
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
              "Network": tier.Network,
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

      [#local componentType = getComponentType(component)]

      [#-- Only include deployed Occurrences --]
      [#local occurrences = getOccurrences(tier, component) ]
      [#local cleanedOccurrences = [] ]

      [#list getOccurrences(tier, component) as occurrence ]        
          [#local cleanedOccurrences += [ getCleanedOccurrence(occurrence) ] ]
      [/#list]

      [#local result += [
        {
          "Id" : id,
          "Type" : componentType,
          "Occurrences" : cleanedOccurrences
        } ] ]

    [/#if]
  [/#list]
  [#return  result ]
[/#function]

[#if deploymentSubsetRequired("blueprint", true)]
  [@toJSON getTenantBlueprint() /]
[/#if]




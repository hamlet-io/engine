[#ftl]
[#include "/bootstrap.ftl" ]

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
      "RequestReference" : commandLineOptions.References.Request,
      "ConfigurationReference" : commandLineOptions.References.Configuration,
      "RunId" : commandLineOptions.Run.Id
    },
    "Tenants" : [
      {
        "Id" : tenantObject.Id,
        "Configuration" : tenantObject,
        "Domains" : domains,
        "Products" : getProductBlueprint()
      }
    ]
  } +
  attributeIfContent("COTMessages", logMessages)]
[#return result]
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
  [#list tier.Components!{} as id, value]
    [#local component =
      {
          "Id" : id,
          "Name" : id
      } + value ]

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

[#-- Redefine the core processing macro --]
[#macro processComponents level]
  [#if (commandLineOptions.Deployment.Unit.Subset!"") == "config" ]
    [@addToDefaultJsonOutput
      content=mergeObjects(getTenantBlueprint() + logMessages) /]
  [/#if]
[/#macro]

[#if (commandLineOptions.Deployment.Unit.Subset!"") == "genplan" ]
  [@initialiseDefaultScriptOutput format=commandLineOptions.Deployment.Output.Format /]
  [@addDefaultGenerationPlan subsets="config" /]
[#else]
  [#assign allDeploymentUnits = true]
  [#assign commandLineOptions =
      mergeObjects(
          commandLineOptions,
          {
              "Deployment" : {
                  "Unit" : {
                      "Name" : ""
                  }
              }
          }
      ) ]
[/#if]

[@generateOutput
  deploymentFramework=commandLineOptions.Deployment.Framework.Name
  type=commandLineOptions.Deployment.Output.Type
  format=commandLineOptions.Deployment.Output.Format
/]

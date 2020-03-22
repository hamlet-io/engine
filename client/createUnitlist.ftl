[#ftl]
[#include "/bootstrap.ftl" ]

[#function getDeploymentUnits ]
  [#local deploymentUnits=[] ]
  [#list tiers as tier]
    [#list tier.Components!{} as id, value]
      [#local component =
        {
            "Id" : id,
            "Name" : id
        } + value ]

      [#if component?is_hash]
        [#local occurrences = getOccurrences(tier, component) ]

        [#list occurrences as occurrence ]
          [#local deploymentUnits =
                    combineEntities(
                      deploymentUnits,
                      asArray((occurrence.Configuration.Solution.DeploymentUnits)![]),
                      UNIQUE_COMBINE_BEHAVIOUR
                    )]
          [#list (occurrence.Occurrences)![] as subOccurrence ]
            [#local deploymentUnits =
              combineEntities(
                deploymentUnits,
                asArray((subOccurrence.Configuration.Solution.DeploymentUnits)![]),
                UNIQUE_COMBINE_BEHAVIOUR
              )]
          [/#list]
        [/#list]
      [/#if]
    [/#list]
  [/#list]
  [#return deploymentUnits ]
[/#function]

[#-- Redefine the core processing macro --]
[#macro processComponents level]
  [#if (commandLineOptions.Deployment.Unit.Subset!"") == "config" ]
    [@addToDefaultJsonOutput
      content={ "DeploymentUnits" : getDeploymentUnits() } + attributeIfContent("COTMessages", logMessages) /]
  [/#if]
[/#macro]

[#if (commandLineOptions.Deployment.Unit.Subset!"") == "generationcontract" ]
  [@initialiseDefaultScriptOutput format=commandLineOptions.Deployment.Output.Format /]
  [@addDefaultGenerationContract subsets="config"  /]
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

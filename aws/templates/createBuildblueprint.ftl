[#ftl]
[#include "/bootstrap.ftl" ]

[#function getComponentBuildBlueprint ]
  [#local result={} ]

  [#list tiers as tier]

    [#list tier.Components!{} as id, value]
        [#local component =
            {
                "Id" : id,
                "Name" : id
            } + value ]

        [#if component?is_hash]
            [#list requiredOccurrences(
                getOccurrences(tier, component),
                getDeploymentUnit() ) as occurrence]

                [#local componentType = getComponentType(component)]

                [#local result += {
                    "Id" : id,
                    "Type" : componentType,
                    "Metadata" :
                        {
                            "Prepared" : .now?iso_utc,
                            "RequestReference" : commandLineOptions.References.Request,
                            "ConfigurationReference" : commandLineOptions.References.Configuration,
                            "RunId" : commandLineOptions.Run.Id
                        } +
                        attributeIfContent("CostCentre", accountObject.CostCentre!""),
                    "Occurrence" : occurrence
                    }
                ]
            [/#list]
        [/#if]
    [/#list]
  [/#list]
  [#return result]
[/#function]

[#-- Redefine the core processing macro --]
[#macro processComponents level]
  [#if (commandLineOptions.Deployment.Unit.Subset!"") == "config" ]
    [@addToDefaultJsonOutput
      content=mergeObjects(getComponentBuildBlueprint(), logMessages )
    /]
  [/#if]
[/#macro]

[#if (commandLineOptions.Deployment.Unit.Subset!"") == "genplan" ]
  [@initialiseDefaultScriptOutput format=commandLineOptions.Deployment.Output.Format /]
  [@addDefaultGenerationPlan subsets="config" /]
[/#if]

[@generateOutput
  deploymentFramework=commandLineOptions.Deployment.Framework.Name
  type=commandLineOptions.Deployment.Output.Type
  format=commandLineOptions.Deployment.Output.Format
/]

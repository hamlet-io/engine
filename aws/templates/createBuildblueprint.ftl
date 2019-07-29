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
                deploymentUnit) as occurrence]

                [#local componentType = getComponentType(component)]

                [#local result += {
                    "Id" : id,
                    "Type" : componentType,
                    "Metadata" :
                        {
                            "Prepared" : .now?iso_utc,
                            "RequestReference" : requestReference,
                            "ConfigurationReference" : configurationReference,
                            "RunId" : runId
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
  [#if (deploymentUnitSubset!"") == "config" ]
    [@addToDefaultJsonOutput content=getComponentBuildBlueprint() /]
  [/#if]
[/#macro]

[#if (deploymentUnitSubset!"") == "genplan" ]
  [@initialiseDefaultScriptOutput format=outputFormat /]
  [@addDefaultGenerationPlan subsets="config" /]
[/#if]

[@generateOutput
  deploymentFramework=deploymentFramework
  type=outputType
  format=outputFormat
/]

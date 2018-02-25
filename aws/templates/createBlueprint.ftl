[#ftl]
[#include "setContext.ftl" ]

[#assign listMode = "blueprint"]

[#assign allDeploymentUnits = true]
[#assign includeRaw = false]

[#function getAggregatorBlueprint ]
  [#local result={} ]
  [#return
    result?has_content?then(
      { "Integrators" : result },
      getIntegratorBlueprint())
  ]
[/#function]

[#function getIntegratorBlueprint]
  [#local result={ tenantId : getTenantBlueprint() } ]
  [#return { "Tenants" : result } ]
[/#function]

[#function getTenantBlueprint]
  [#local result={ productId : getProductBlueprint() } ]
  [#return { "Products" : result } ]
[/#function]

[#function getProductBlueprint ]
  [#local result={ environmentId : getEnvironmentBlueprint() } ]
  [#return { "Environments" : result } ]
[/#function]

[#function getEnvironmentBlueprint ]
  [#local result={ segmentId : getSegmentBlueprint() } ]
  [#return { "Segments" : result } ]
[/#function]

[#function getSegmentBlueprint ]
  [#local result={} ]
  [#list tiers as tier]
    [#assign tierId = tier.Id]
    [#assign tierName = tier.Name]
    [#local result+={ tierId : getTierBlueprint(tier) } ]
  [/#list]
  [#return 
    { "Tiers" : result} +
    includeRaw?then({ "Raw" : tiers }, {}) ]
[/#function]

[#function getTierBlueprint tier]
  [#local result={} ]
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
        {
          id : {
            "Id" : componentId,
            "Name" : componentName,
            "Type" : componentType,
            "Occurrences" : getOccurrences(component, tier, component, "")
          }
        } ]
    [/#if]
  [/#list]
  [#return
    { "Components" : result} +
    includeRaw?then({"Raw" : tier.Components!{}},{}) ]
[/#function]

[#if deploymentSubsetRequired("blueprint", true)]
  [@toJSON getAggregatorBlueprint() /]
[/#if]




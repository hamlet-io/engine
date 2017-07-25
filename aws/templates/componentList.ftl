[#ftl]
[@noResourcesCreated /]
[#list tiers as tier]
    [#assign tierId = tier.Id]
    [#assign tierName = tier.Name]
    [#if tier.Components??]
        [#list tier.Components?values as component]
            [#if deploymentRequired(component, deploymentUnit)]
                [#assign componentId = getComponentId(component)]
                [#assign componentName = getComponentName(component)]
                [#assign componentType = getComponentType(component)]
                [#assign componentIdStem = formatComponentId(tier, component)]
                [#assign componentShortName = formatComponentShortName(tier, component)]
                [#assign componentShortNameWithType = formatComponentShortNameWithType(tier, component)]
                [#assign componentShortFullName = formatComponentShortFullName(tier, component)]
                [#assign componentFullName = formatComponentFullName(tier, component)]
                [#assign dashboardRows = []]
                [#assign multiAZ = component.MultiAZ!solnMultiAZ]
                [#list compositeLists as compositeList]
                    [#include compositeList]
                [/#list]
                [#if dashboardRows?has_content]
                    [#assign dashboardComponents += [
                            {
                                "Title" : component.Title?has_content?then(
                                            component.Title,
                                            formatComponentName(tier, component)),
                                "Rows" : dashboardRows
                            }
                        ]
                    ]
                [/#if]
            [/#if]
        [/#list]
    [/#if]
[/#list]

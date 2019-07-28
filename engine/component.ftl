[#ftl]

[#-- Core processing of tiers/components --]

[#-- Component configuration is extended dynamically by each component type --]
[#assign componentConfiguration = {} ]

[#-- Resource Groups --]
[#assign DEFAULT_RESOURCE_GROUP = "default"]
[#assign DNS_RESOURCE_GROUP = "dns"]

[#-- Attributes are shared across providers, or provider specific --]
[#assign SHARED_ATTRIBUTES = "shared"]

[#-- Placement profiles --]
[#assign DEFAULT_PLACEMENT_PROFILE = "default"]

[#-- Helper macro - not for general use --]
[#macro mergeComponentConfiguration type configuration]
    [#assign componentConfiguration =
        mergeObjects(
            componentConfiguration,
            {
                type: configuration
            }
        )
    ]
[/#macro]

[#-- Macros to assemble the component configuration --]
[#macro addComponent type properties attributes dependencies=[] ]
    [@mergeComponentConfiguration
        type=type
        configuration=
            {
                "Properties" : asArray(properties)
            } +
            attributeIfContent("Dependencies", dependencies, asArray(dependencies))
    /]
    [#-- Default resource group --]
    [@addResourceGroupInformation
        type=type
        attributes=attributes
        provider=SHARED_ATTRIBUTES
        resourceGroup=DEFAULT_RESOURCE_GROUP
    /]
[/#macro]

[#macro addChildComponent type properties attributes parent childAttribute linkAttributes dependencies=[] ]
    [@addComponent
        type=type
        properties=properties
        attributes=attributes
        dependencies=dependencies
    /]

    [#local children =
        ((componentConfiguration[parent].Components)![]) +
        [
            {
                "Type" : type,
                "Component" : childAttribute,
                "Link" : asArray(linkAttributes)
            }
        ]
    ]
    [@mergeComponentConfiguration
        type=parent
        configuration=
            {
                "Components" : children
            }
    /]
[/#macro]


[#-- Not for general use - framework only --]
[#assign coreComponentChildConfiguration = [
    {
        "Names" : ["Export"],
        "Default" : []
    },
    {
        "Names" : ["DeploymentUnits"],
        "Default" : []
    }
] ]

[#macro addResourceGroupInformation type attributes provider resourceGroup services=[] ]
    [#-- Special processing for profiles --]
    [#if
        (provider == SHARED_ATTRIBUTES) &&
        (resourceGroup == DEFAULT_RESOURCE_GROUP) ]
        [#local extendedAttributes = [] ]
        [#local profileAttribute = coreProfileChildConfiguration[0] ]
        [#list attributes as attribute ]
            [#if asArray(attribute.Names!attribute.Name)?seq_contains("Profiles")]
                [#local profileAttribute +=
                        {
                            "Children" :
                                profileAttribute.Children +
                                attribute.Children
                        }
                    ] ]
            [#else]
                [#local extendedAttributes += [attribute] ]
            [/#if]
        [/#list]
        [#local extendedAttributes += [profileAttribute] ]
    [/#if]
    [@mergeComponentConfiguration
        type=type
        configuration=
            {
                "ResourceGroups" : {
                    resourceGroup : {
                        "Attributes" : {
                            provider :
                                asArray(extendedAttributes!attributes) + coreComponentChildConfiguration
                        }
                    } +
                    valueIfContent(
                        {
                            "Services" : {
                                provider : asArray(services)
                            }
                        },
                        services
                    )
                }
            }
    /]
[/#macro]

[#function getComponentDependencies type]
    [#return (componentConfiguration[type].Dependencies)![] ]
[/#function]

[#function getComponentResourceGroups type]
    [#return (componentConfiguration[type].ResourceGroups)!{} ]
[/#function]

[#function getComponentChildren type]
    [#return (componentConfiguration[type].Components)![] ]
[/#function]

[#function getComponentChildrenAttributes type]
    [#local result = [] ]
    [#list (componentConfiguration[type].Components)![] as child]
        [#local result += [child.Component]]
    [/#list]
    [#return result]
[/#function]

[#function getComponentChildType child]
    [#return child.Type ]
[/#function]

[#function getComponentChildAttribute child]
    [#return child.Component ]
[/#function]

[#function getComponentChildLinkAttributes child]
    [#return asArray(child.Link![]) ]
[/#function]

[#function getResourceGroupPlacement key profile]
    [#return profile[key]!{} ]
[/#function]

[#function invokeComponentMacro occurrence resourceGroup levels=[] parent={} baseState={} ]
    [#local placement = (occurrence.State.ResourceGroups[resourceGroup].Placement)!{} ]
    [#if placement?has_content]
        [#local macroOptions = [] ]
            [#list asArray(levels) as level]
                [#if level?has_content]
                    [#local macroOptions +=
                        [
                            [placement.Provider, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework, level],
                            [placement.Provider, occurrence.Core.Type, placement.DeploymentFramework, level],
                            [placement.Provider, resourceGroup, placement.DeploymentFramework, level]
                        ]]
                [#else]
                    [#local macroOptions +=
                        [
                            [placement.Provider, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework],
                            [placement.Provider, occurrence.Core.type, placement.DeploymentFramework],
                            [placement.Provider, resourceGroup, placement.DeploymentFramework]
                        ]]
                [/#if]
            [/#list]
        [#local macro = getFirstDefinedDirective(macroOptions)]
        [#if macro?has_content]
            [#if parent?has_content || baseState?has_content]
                [@(.vars[macro])
                    occurrence=occurrence
                    parent=parent
                    baseState=baseState /]
            [#else]
                [@(.vars[macro])
                    occurrence=occurrence /]
            [/#if]
            [#return true]
        [#else]
            [@debug
                message="Unable to invoke any of the macro options"
                context=macroOptions
                enabled=false
            /]
        [/#if]
    [/#if]
    [#return false]
[/#function]

[#function invokeSetupMacro occurrence resourceGroup levels=[] ]
    [#return
        invokeComponentMacro(
            occurrence,
            resourceGroup,
            levels,
            {},
            {}
        ) ]
[/#function]

[#function invokeStateMacro occurrence resourceGroup parent={} baseState={} ]
    [#return
        invokeComponentMacro(
            occurrence,
            resourceGroup,
            "state",
            parent,
            baseState
        ) ]
[/#function]

[#-- Tiers --]

[#-- Get a tier --]
[#assign tiers = [] ]
[#function getTier tier]
    [#if tier?is_hash]
        [#local tierId = (tier.Id)!"" ]
    [#else]
        [#local tierId = tier ]
    [/#if]

    [#-- Special processing for the "all" tier --]
    [#if tierId == "all"]
        [#return
          {
              "Id" : "all",
              "Name" : "all"
          } ]
    [/#if]

    [#list tiers as knownTier]
        [#if knownTier.Id == tierId]
            [#return knownTier]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#function getTierNetwork tier]
    [#return (getTier(tier).Network)!{}]
[/#function]

[#-- Get the id for a tier --]
[#function getTierId tier]
    [#return getTier(tier).Id!""]
[/#function]

[#-- Get the name for a tier --]
[#function getTierName tier]
    [#return getTier(tier).Name!""]
[/#function]

[#-- Get the id for a component --]
[#function getComponentId component]
    [#if component?is_hash]
        [#return component.Id?split("-")[0]]
    [#else]
        [#return component?split("-")[0]]
    [/#if]
[/#function]

[#-- Get the name for a component --]
[#function getComponentName component]
    [#if component?is_hash]
        [#return component.Name?split("-")[0]]
    [#else]
        [#return component?split("-")[0]]
    [/#if]
[/#function]

[#-- Get the type for a component --]
[#function getComponentType component]
    [#if ! (component?is_hash && component.Id?has_content) ]
        [@precondition function="getComponentType" context=component /]
        [#return "???"]
    [/#if]

    [#local result = "" ]

    [#if component.Type?has_content]
        [#-- Explicitly provided --]
        [#local result = component.Type]
    [#else]
        [#-- Part of component id --]
        [#local idParts = component.Id?split("-")]
        [#if idParts[1]?has_content]
            [#local result = idParts[1]]
        [#else]
            [#-- type specific attribute --]
            [#list component?keys as key]
                [#switch key?lower_case]
                    [#case "id"]
                    [#case "name"]
                    [#case "title"]
                    [#case "description"]
                    [#case "deploymentunits"]
                    [#case "multiaz"]
                        [#break]
                    [#default]
                        [#local result = key]
                        [#break]
                [/#switch]
            [/#list]
        [/#if]
    [/#if]

    [#-- Handle legacy component names --]
    [#switch result?lower_case]
        [#case DB_LEGACY_COMPONENT_TYPE]
            [#return DB_COMPONENT_TYPE]
            [#break]
        [#case ES_LEGACY_COMPONENT_TYPE]
            [#return ES_COMPONENT_TYPE]
            [#break]
        [#case LB_LEGACY_COMPONENT_TYPE ]
            [#return LB_COMPONENT_TYPE]
            [#break]
    [/#switch]
    [#return result?lower_case]
[/#function]

[#-- Get the type object for a component --]
[#function getComponentTypeObjectAttribute component]
    [#local type = getComponentType(component) ]
    [#list component as key,value]
        [#if key?lower_case == type]
            [#return key]
        [#-- Backwards Compatability for Component renaming --]
        [#else]
            [#switch key?lower_case]
                [#case DB_LEGACY_COMPONENT_TYPE]
                [#case ES_LEGACY_COMPONENT_TYPE]
                [#case LB_LEGACY_COMPONENT_TYPE]
                    [#return key]
                    [#break]
            [/#switch]
       [/#if]
    [/#list]
    [#return "" ]
[/#function]

[#-- Get the type object for a component --]
[#function getComponentTypeObject component]
    [#local typeObject = component[getComponentTypeObjectAttribute(component)]!{} ]
    [#return valueIfTrue(typeObject, typeObject?is_hash) ]
[/#function]

[#-- Get a component within a tier --]
[#function getComponent tierId componentId type=""]
    [#list (getTier(tierId).Components)!{} as key, value]
        [#if value?is_hash]
            [#local component =
                {
                    "Id" : key,
                    "Name" : key
                } + value ]
            [#if
                (
                    (component.Id == componentId) ||
                    (
                    type?has_content &&
                    (getComponentId(component) == componentId) &&
                    (getComponentType(component) == type)
                    )
                ) ]
                [#return
                    component +
                    {
                        "Type" : getComponentType(component),
                        "Tier" : tierId
                    }]
            [/#if]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

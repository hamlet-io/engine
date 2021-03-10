[#ftl]

[#---------------------------------------------
-- Public functions for component processing --
-----------------------------------------------]

[#-- Component configuration is extended dynamically by each component type --]
[#assign componentConfiguration = {} ]

[#function findComponentMarkers]
    [#local markers =
        getPluginTree(
            "/",
            {
                "Regex" : [r"id\.ftl"],
                "AddEndingWildcard" : false,
                "MinDepth" : 4,
                "MaxDepth" : 4,
                "FilenameGlob" : r"id.ftl"
            }
        )
    ]
    [#return markers?sort_by("Path")]
[/#function]

[#-- Resource Groups --]
[#assign DEFAULT_RESOURCE_GROUP = "default"]
[#assign DNS_RESOURCE_GROUP = "dns"]

[#-- Attributes are shared across providers, or provider specific --]
[#assign SHARED_ATTRIBUTES = "shared"]
[#assign DEPLOYMENT_ATTRIBUTES = "deployment"]

[#-- Placement profiles --]
[#assign DEFAULT_PLACEMENT_PROFILE = "default"]

[#-- Macros to assemble the component configuration --]
[#macro addComponent type properties attributes dependencies=[] ]

    [@internalMergeComponentConfiguration
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
    [@internalMergeComponentConfiguration
        type=parent
        configuration=
            {
                "Components" : children
            }
    /]
[/#macro]

[#-- Enables Deployment support for the component --]
[#macro addComponentDeployment type defaultGroup defaultPriority=100 defaultUnit="" lockAttributes=false   ]
    [#local deploymentAttributes = [
        {
            "Names" : "Unit",
            "Types" : STRING_TYPE,
            "Default" : defaultUnit
        } +
        attributeIfTrue(
            "Values",
            lockAttributes,
            [ defaultUnit ]
        ),
        {
            "Names" : "Group",
            "Types" : STRING_TYPE,
            "Default" : defaultGroup
        } +
        attributeIfTrue(
            "Values",
            lockAttributes,
            [ defaultGroup ]
        ),
        {
            "Names" : "Priority",
            "Types" : NUMBER_TYPE,
            "Default" : defaultPriority
        } +
        attributeIfTrue(
            "Values",
            lockAttributes,
            [ defaultPriority ]
        )
    ]]

    [@addResourceGroupInformation
        type=type
        attributes=deploymentAttributes
        provider=DEPLOYMENT_ATTRIBUTES
        resourceGroup=DEFAULT_RESOURCE_GROUP
        prefixed=true
    /]
[/#macro]

[#-- Not for general use - framework only --]
[#assign coreComponentDeploymentUnitConfiguration = 
    [
        {
            "Names" : ["DeploymentUnits", "deployment:Unit"],
            "Description" : "An singleton instance of the component, Instance & Version configuration.",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        }
    ]
]

[#assign coreComponentChildConfiguration = 
    [
        {
            "Names" : ["Export"],
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : [ "Instances" ],
            "Description" : "Instances of a component configuration",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Versions",
                    "Description" : "Versions of the components instance.",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : [ "Extensions", "Fragment", "Container" ],
                            "Description" : "Extensions to invoke as part of component processing",
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
                        }
                    ] + coreComponentDeploymentUnitConfiguration
                }
            ] + 
            coreComponentDeploymentUnitConfiguration
        }
    ] +
    coreComponentDeploymentUnitConfiguration
]

[#macro addResourceGroupAttributeValues type extensions provider resourceGroup=DEFAULT_RESOURCE_GROUP]

    [@internalMergeComponentConfiguration
        type=type
        configuration=
            {
                "ResourceGroups" : {
                    resourceGroup : {
                        "Extensions" : {
                            provider :
                                extensions
                        }
                    }
                }
            }
    /]

[/#macro]

[#macro addResourceGroupInformation type attributes provider resourceGroup services=[] prefixed=true ]
    [#if provider == SHARED_ATTRIBUTES ]
        [#-- Special processing for profiles --]
        [#if resourceGroup == DEFAULT_RESOURCE_GROUP ]
            [#local providerAttributes = [] ]
            [#local profileAttribute = coreProfileChildConfiguration[0] ]
            [#local settingsNamespacesAttribute = coreSettingsNamespacesConfiguration[0] ]
            [#list attributes as attribute ]
                [#if asArray(attribute.Names!attribute.Name![])?seq_contains("Profiles")]
                    [#local profileAttribute +=
                            {
                                "Children" :
                                    profileAttribute.Children +
                                    attribute.Children
                            }
                        ]
                [#else]
                    [#local providerAttributes += [attribute] ]
                [/#if]
            [/#list]
            [#local providerAttributes += [profileAttribute, settingsNamespacesAttribute] ]
        [#else]
            [#local providerAttributes = attributes ]
        [/#if]

        [#local providerAttributes += coreComponentChildConfiguration ]
    [#else]
        [#if prefixed]
            [#-- Handle prefixing of provider specific attributes --]
            [#local providerAttributes = [] ]
            [#list attributes as attribute ]
                [#local prefixedNames = [] ]
                [#list asArray(attribute.Names!attribute.Name![]) as name]
                    [#local prefixedNames += [provider + ":" + name] ]
                [/#list]
                [#local providerAttributes +=
                    [
                        attribute +
                        {
                            "Names" : prefixedNames
                        }
                    ]
                ]
            [/#list]
        [#else]
            [#local providerAttributes = attributes ]
        [/#if]
    [/#if]

    [@internalMergeComponentConfiguration
        type=type
        configuration=
            {
                "ResourceGroups" : {
                    resourceGroup : {
                        "Attributes" : {
                            provider :
                                providerAttributes
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

[#function getComponentLegacyTypes type]
    [#local result = [] ]
    [#list legacyTypeMapping as legacyType,canonicalType]
        [#if type == canonicalType]
            [#local result += [legacyType] ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function getComponentChildren type]
    [#return (componentConfiguration[type].Components)![] ]
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

[#function getComponentChildrenAttributes type]
    [#local result = [] ]
    [#list (componentConfiguration[type].Components)![] as child]
        [#local result += [getComponentChildAttribute(child)] ]
    [/#list]
    [#return result]
[/#function]

[#function getComponentChildrenLinkAttributes type]
    [#local result = [] ]
    [#list (componentConfiguration[type].Components)![] as child]
        [#local result += getComponentChildLinkAttributes(child)] ]
    [/#list]
    [#return result]
[/#function]

[#function getResourceGroupPlacement key profile]
    [#return profile[key]!{} ]
[/#function]

[#function invokeComponentMacro occurrence resourceGroup entrance="" qualifiers=[] parent={} includeShared=true ]
    [#local placement = (occurrence.State.ResourceGroups[resourceGroup].Placement)!{} ]
    [#if placement?has_content]
        [#local macroOptions = [] ]
        [#list asArray(qualifiers) as qualifier]
            [#local macroOptions +=
                [
                    [placement.Provider, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                    [placement.Provider, occurrence.Core.Type, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                    [placement.Provider, resourceGroup, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                    [placement.Provider, resourceGroup, placement.DeploymentFramework  ] + asFlattenedArray(qualifier, true)
                ]]
        [/#list]

        [#local macroOptions +=
            [
                [placement.Provider, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework, entrance],
                [placement.Provider, occurrence.Core.Type, placement.DeploymentFramework, entrance],
                [placement.Provider, resourceGroup, placement.DeploymentFramework, entrance],
                [placement.Provider, resourceGroup, placement.DeploymentFramework ]
            ]]
        [#if includeShared ]
            [#list asArray(qualifiers) as qualifier]
                [#local macroOptions +=
                    [
                        [ SHARED_PROVIDER, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                        [ SHARED_PROVIDER, occurrence.Core.Type, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                        [ SHARED_PROVIDER, occurrence.Core.Type, commandLineOptions.Deployment.Framework.Name, entrance] + asFlattenedArray(qualifier, true),
                        [ SHARED_PROVIDER, resourceGroup, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                        [ SHARED_PROVIDER, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                        [ SHARED_PROVIDER, entrance ] + asFlattenedArray(qualifier, true)
                    ]]
            [/#list]

            [#local macroOptions += [
                [ SHARED_PROVIDER, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework, entrance],
                [ SHARED_PROVIDER, occurrence.Core.Type, placement.DeploymentFramework, entrance],
                [ SHARED_PROVIDER, occurrence.Core.Type, commandLineOptions.Deployment.Framework.Name, entrance],
                [ SHARED_PROVIDER, resourceGroup, placement.DeploymentFramework, entrance],
                [ SHARED_PROVIDER, placement.DeploymentFramework, entrance ],
                [ SHARED_PROVIDER, entrance ]
            ]]
        [/#if]
        [#local macro = getFirstDefinedDirective(macroOptions)]
        [#if macro?has_content]
            [#if parent?has_content ]
                [@(.vars[macro])
                    occurrence=occurrence
                    parent=parent /]
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

[#function invokeSetupMacro occurrence resourceGroup qualifiers=[] ]
    [#return
        invokeComponentMacro(
            occurrence,
            resourceGroup,
            "setup",
            qualifiers,
            {}
        )]
[/#function]

[#function invokeStateMacro occurrence resourceGroup parent={} ]
    [#return
        invokeComponentMacro(
            occurrence,
            resourceGroup,
            "",
            [ "state" ],
            parent,
            false
        )]
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

[#-- Get the canonical type for a component --]
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

    [#-- Canonical type values are always lower case --]
    [#local result = result?lower_case]

    [#-- Handle legacy component names --]
    [#return legacyTypeMapping[result]!result ]

[/#function]

[#-- Get the attribute for the type object for a component --]
[#function getComponentTypeObjectAttribute component]
    [#local type = getComponentType(component) ]
    [#list component as key,value]
        [#-- type object based on canonical type --]
        [#if key?lower_case == type]
            [#return key]
        [/#if]
        [#-- type object based on legacy type --]
        [#if (legacyTypeMapping[key?lower_case]!"") == type ]
            [#return key]
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

[#-------------------------------------------------------
-- Internal support functions for component processing --
---------------------------------------------------------]

[#-- Helper macro - not for general use --]
[#macro internalMergeComponentConfiguration type configuration]
    [#assign componentConfiguration =
        mergeObjects(
            componentConfiguration,
            {
                type: configuration
            }
        ) ]
[/#macro]

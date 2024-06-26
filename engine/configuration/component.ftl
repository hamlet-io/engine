[#ftl]

[#---------------------------------------------
-- Public functions for component processing --
-----------------------------------------------]

[#-- Configuration Sets not yet implemented --]
[#-- Placeholder for schema generation --]
[#assign COMPONENT_CONFIGURATION_SCOPE = "Component" ]

[@addConfigurationScope
    id=COMPONENT_CONFIGURATION_SCOPE
    description="Defines the functionality required in your solution"
/]


[#-- Component configuration is extended dynamically by each component type --]
[#assign componentConfiguration = {} ]
[#assign deploymentState = {} ]

[#-- Legacy type mappings --]
[#assign legacyTypeMapping = {} ]

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
[#assign BASE_ATTRIBUTES = "base"]

[#-- Placement profiles --]
[#assign DEFAULT_PLACEMENT_PROFILE = "default"]

[#-- Macros to assemble the component configuration --]
[#macro addComponent type properties attributes dependencies=[] additionalResourceGroups=[] includeTypeAttr=true ]

    [#-- Basic configuration --]
    [@internalMergeComponentConfiguration
        type=type
        configuration=
            {
                "Properties" : asArray(properties)
            } +
            attributeIfContent("Dependencies", dependencies, asArray(dependencies))
    /]

    [#-- Resource groups --]
    [#list [DEFAULT_RESOURCE_GROUP] + asArray(additionalResourceGroups) as resourceGroup]
        [@internalMergeComponentConfiguration
            type=type
            configuration=
                {
                    "ResourceGroups" : {
                        resourceGroup : {}
                    }
                }
        /]
    [/#list]

    [#-- Default resource group --]
    [@addResourceGroupInformation
        type=type
        attributes=attributes
        provider=SHARED_ATTRIBUTES
        resourceGroup=DEFAULT_RESOURCE_GROUP
    /]

    [@addComponentBase
        type=type
        includeTypeAttr=includeTypeAttr
    /]
[/#macro]

[#macro addChildComponent type properties attributes parent childAttribute linkAttributes dependencies=[] ]
    [@addComponent
        type=type
        properties=properties
        attributes=attributes
        dependencies=dependencies
        includeTypeAttr=false
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

[#macro addLegacyComponentTypeMapping type legacyType ]
    [#assign legacyTypeMapping = mergeObjects(
        legacyTypeMapping,
        {
            legacyType : type
        }
    )]
[/#macro]

[#-- Enables Deployment support for the component --]
[#macro addComponentDeployment type defaultGroup defaultPriority=100 defaultUnit="" lockAttributes=false   ]
    [#local deploymentAttributes = [
        {
            "Names" : "shared:DeploymentUnits",
            "Types" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "Unit",
            "Types" : STRING_TYPE,
            "Default" : defaultUnit
        },
        {
            "Names": "Locks",
            "Description" : "Apply locks on the deployment to control what can be completed",
            "Children": [
                {
                    "Names" : "Delete",
                    "Description" : "Don't allow the deployment to be deleted",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
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

[#macro addOccurrenceDeploymentState occurrence ]
    [@internalMergeDeploymentState
        deploymentGroup=getOccurrenceDeploymentGroup(occurrence)
        deploymentUnit=getOccurrenceDeploymentUnit(occurrence)
        state=isOccurrenceDeployed(occurrence)
    /]
[/#macro]

[#macro addDeploymentState deploymentGroup deploymentUnit deployed ]
    [@internalMergeDeploymentState
        deploymentGroup=deploymentGroup
        deploymentUnit=deploymentUnit
        state=deployed
    /]
[/#macro]

[#function getDeploymentUnitStates deploymentGroup deploymentUnit ]
    [#return (deploymentState[deploymentGroup][deploymentUnit].DeployStates)![] ]
[/#function]

[#function getDeploymentGroupsFromState ]
    [#return deploymentState?keys ]
[/#function]

[#macro addComponentBase type includeTypeAttr=true ]

    [#local attributes = [
        {
            "Names" : "Enabled",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Description",
            "Types" : STRING_TYPE,
            "Description" : "A description of the component",
            "Default" : ""
        },
        {
            "Names" : "Title",
            "Types" : STRING_TYPE,
            "Description" : "A longer form title of the component",
            "Default" : ""
        },
        {
            "Names" : "Export",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Instances",
            "Description" : "Instances of a component configuration",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Versions",
                    "Description" : "Versions of the components instance.",
                    "SubObjects" : true,
                    "Children" : []
                }
            ]
        },
        {
            "Names" : [ "SettingNamespaces" ],
            "Description" : "Additional namespaces to use during settings lookups",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Match",
                    "Description" : "How to match the namespace with available settings",
                    "Types" : STRING_TYPE,
                    "Values" : [ "exact", "partial" ],
                    "Default" : "exact"
                },
                {
                    "Names" : "Order",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : [
                        "Tier",
                        "Component",
                        "Type",
                        "SubComponent",
                        "Instance",
                        "Version",
                        "Name"
                    ]
                },
                {
                    "Names" : "IncludeInNamespace",
                    "Children" : [
                        {
                            "Names" : "Tier",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "Component",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "Type",
                            "Types"  : BOOLEAN_TYPE,
                            "Default" : false
                        }
                        {
                            "Names" : "SubComponent",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "Instance",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "Version",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "Name",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : "Name",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        {
            "Names" : "Settings",
            "Description" : "Application settings that can provide configuration for code",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Sensitive",
                    "Description" : "Hide the value of this setting when using it in output",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Internal",
                    "Description" : "Don't include this setting as part of environment variable generation",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Value",
                    "Description" : "The value of the setting",
                    "Types" : ANY_TYPE,
                    "Mandatory" : true
                }
            ]
        },
        {
            "Names": "Tags",
            "Description": "Key value pairs to apply to resources to identify them",
            "Children": [
                {
                    "Names": "Common",
                    "Description": "Include tags based on properties of the occurrence",
                    "Children" : [
                        {
                            "Names": "Prefix",
                            "Description": "A prefix to apply to common tags",
                            "Types" : STRING_TYPE,
                            "Default": "cot:"
                        },
                        {
                            "Names" : "Layers",
                            "Description" : "Include the names of the active layers",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "Solution",
                            "Description" : "Include details of the solution",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names": "Deployment",
                            "Description": "Include details of the deployment",
                            "Types": BOOLEAN_TYPE,
                            "Default": true
                        },
                        {
                            "Names": "CostCentre",
                            "Description": "Include the cost centre for the account",
                            "Types": BOOLEAN_TYPE,
                            "Default": true
                        },
                        {
                            "Names": "Component",
                            "Description": "Include tags provided by the component",
                            "Types": BOOLEAN_TYPE,
                            "Default": true
                        }
                        {
                            "Names" : "Name",
                            "Description": "The component name attribute to use",
                            "Types" : STRING_TYPE,
                            "Values": [ "FullName", "FullRawName", "RawName", "Name", "ShortName", "ShortRawName", "ShortFullName", "ShortRawFullName" ],
                            "Default" : "FullName"
                        }
                    ]
                },
                {
                    "Names": "Additional",
                    "Description": "Extra tags to include",
                    "SubObjects": true,
                    "Children": [
                        {
                            "Names": "Key",
                            "Description": "The key of the tag ( uses the key of this object by default)",
                            "Types": STRING_TYPE
                        }
                        {
                            "Names": "Value",
                            "Description": "The value of the tag",
                            "Types": STRING_TYPE,
                            "Mandatory": true
                        },
                        {
                            "Names": "Enabled",
                            "Description": "Include the tag",
                            "Types": BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                }
            ]
        }
    ] +
    includeTypeAttr?then(
        [
            {
                "Names" : "Type",
                "Types" : STRING_TYPE,
                "Description" : "The components type"
            }
        ],
        []
    )]

    [@addResourceGroupInformation
        type=type
        attributes=attributes
        provider=BASE_ATTRIBUTES
        resourceGroup=DEFAULT_RESOURCE_GROUP
        prefixed=false
    /]
[/#macro]

[#macro addResourceGroupAttributeValues type extensions provider resourceGroup=DEFAULT_RESOURCE_GROUP]

    [@internalMergeComponentConfiguration
        type=type
        configuration=
            {
                "ResourceGroups" : {
                    resourceGroup : {
                        "Extensions" : {
                            provider : extensions
                        }
                    }
                }
            }
    /]

[/#macro]

[#macro addResourceGroupInformation type attributes provider resourceGroup services=[] prefixed=true locations={} ]

    [#-- Ensure resource group is known - it should have been registered when the component was registered --]
    [#if !componentConfiguration[type]?? ]
        [@fatal
            message='Internal error - attempt to add ResourceGroup information for provider "${provider}" on unknown component type "${type}"'
        /]
        [#return]
    [#else]
        [#if !componentConfiguration[type].ResourceGroups[resourceGroup]?? ]
            [@fatal
                message='Internal error - attempt to provide information for unknown ResourceGroup "${resourceGroup}" on component type "${type}" for provider "${provider}"'
            /]
            [#return]
        [/#if]
    [/#if]

    [#local attributes = expandBaseCompositeConfiguration(attributes)]

    [#if provider == SHARED_ATTRIBUTES ]
        [#-- Special processing for profiles --]
        [#if resourceGroup == DEFAULT_RESOURCE_GROUP ]
            [#local providerAttributes = [] ]
            [#local profileAttribute = (getAttributeSet(CORE_PROFILE_ATTRIBUTESET_TYPE).Attributes)[0] ]
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
            [#local providerAttributes += [profileAttribute] ]
        [#else]
            [#local providerAttributes = attributes ]
        [/#if]

    [#else]
        [#if prefixed]
            [#-- Handle prefixing of provider specific attributes --]
            [#local providerAttributes = addPrefixToAttributes( attributes, provider, true, false, false )]
        [#else]
            [#local providerAttributes = attributes ]
        [/#if]
    [/#if]

    [#local locationAttributes =
        [
            {
                "Names" : "Locations",
                "Description" : "Expected locations",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Mandatory",
                        "Description" : "Is location always required?",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "TargetComponentTypes",
                        "Description" : "Supported types for targetted components",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Mandatory" : true
                    }
                ]
            }
        ]
    ]

    [#local locationsMessages =
        getCompositeObjectResult(
            "messages",
            locationAttributes,
            { "Locations" : locations }
        ) ]

    [#if locationsMessages?has_content ]
        [@fatal
            message='Invalid location configuration for component "${type}" and ResourceGroup "${resourceGroup}"'
            context=locationErrorMessages
        /]
    [/#if]

    [#local locationsObject =
        getCompositeObjectResult(
            "object",
            locationAttributes,
            { "Locations" : locations }
        ).Locations ]

    [@internalMergeComponentConfiguration
        type=type
        configuration=
            {
                "ResourceGroups" : {
                    resourceGroup :
                    valueIfContent(
                        {
                            "Attributes" : {
                                provider : providerAttributes
                            }
                        },
                        providerAttributes
                    ) +
                    valueIfContent(
                        {
                            "Services" : {
                                provider : asArray(services)
                            }
                        },
                        services
                    ) +
                    valueIfContent(
                        {
                            "Locations" : {
                                provider : locationsObject
                            }
                        },
                        locationsObject
                    )
                }
            }
    /]
[/#macro]

[#function getAllComponentConfiguration ]
    [#return componentConfiguration ]
[/#function]

[#function getComponentDependencies type]
    [#return (componentConfiguration[type].Dependencies)![] ]
[/#function]

[#function getComponentResourceGroups type]
    [#return (componentConfiguration[type].ResourceGroups)!{} ]
[/#function]

[#function getComponentResourceGroupLocations resourceGroup provider]
    [#return (resourceGroup.Locations[provider])!{} ]
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

[#function getComponentResourceGroupAttributes componentResourceGroup provider]
    [#if (componentResourceGroup.Extensions![])?has_content]

        [#local extendedSharedAttributes =
            extendAttributes(
                (componentResourceGroup.Attributes[SHARED_ATTRIBUTES])![],
                (componentResourceGroup.Extensions[provider])![],
                provider)]
    [#else]
        [#local extendedSharedAttributes = (componentResourceGroup.Attributes[SHARED_ATTRIBUTES])![] ]
    [/#if]

    [#return
        extendedSharedAttributes +
        ((componentResourceGroup.Attributes[BASE_ATTRIBUTES])![]) +
        ((componentResourceGroup.Attributes[DEPLOYMENT_ATTRIBUTES])![]) +
        ((componentResourceGroup.Attributes[provider])![])
    ]
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
                        [ SHARED_PROVIDER, occurrence.Core.Type, getCLODeploymentFramework(), entrance] + asFlattenedArray(qualifier, true),
                        [ SHARED_PROVIDER, resourceGroup, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                        [ SHARED_PROVIDER, placement.DeploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                        [ SHARED_PROVIDER, entrance ] + asFlattenedArray(qualifier, true)
                    ]]
            [/#list]

            [#local macroOptions += [
                [ SHARED_PROVIDER, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework, entrance],
                [ SHARED_PROVIDER, occurrence.Core.Type, placement.DeploymentFramework, entrance],
                [ SHARED_PROVIDER, occurrence.Core.Type, getCLODeploymentFramework(), entrance],
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

    [#list getTiers() as knownTier]
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

    [#-- Canonical type values are always lower case --]
    [#local result = result?lower_case]

    [#-- Handle legacy component names --]
    [#return legacyTypeMapping[result]!result ]

[/#function]

[#--
Get the type object for a component

TODO(mfl): Add a warning if a type specific attribute is located.

To simplify solutions, it is preferred to directly use the Type
attribute and NOT have specific object for the type. Rather, the
component configuration can be at the same level as the Type.
For now, the logic still prefers a type specific attribute if
present, but once the cutover is largely complete, a warning
needs to be added if the condition is detected, and eventually
the warning can be changed to an error. The last phase does
imply a breaking change so needs to be managed carefully.
--]
[#function getComponentTypeObject component]
    [#-- Check for type specific attribute --]
    [#local typeObject = component[internalGetComponentTypeObjectAttribute(component)]!{} ]
    [#if component.Type?? && (!typeObject?has_content) ]
        [#-- No type specific attribute but the type is explicitly provided --]
        [#return component]
    [/#if]
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


[#macro internalMergeDeploymentState deploymentGroup deploymentUnit state ]

    [#if deploymentUnit?has_content && state?has_content ]
        [#local unitState = (deploymentState[deploymentGroup][deploymentUnit].DeployStates)![] ]

        [#assign deploymentState = (
            mergeObjects(
                deploymentState,
                {
                    deploymentGroup : {
                        deploymentUnit : {
                            "DeployStates" : combineEntities( unitState, [ state ], APPEND_COMBINE_BEHAVIOUR)
                        }
                    }
                }
            )
        )]
    [/#if]
[/#macro]

[#-- Get the attribute for the type object for a component --]
[#function internalGetComponentTypeObjectAttribute component]
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

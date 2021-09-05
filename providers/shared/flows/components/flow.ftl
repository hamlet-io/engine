[#ftl]
[#------------------------------------------
-- Public functions for component flow processing --
--------------------------------------------]

[#-- Main component processing flow --]
[#macro default_flow_components level ]

    [#local start = .now]
    [@timing message="Starting component processing ..." /]
    [#list tiers as tier]
        [#list (tier.Components!{}) as key, value]
            [#local component =
                {
                    "Id" : key,
                    "Name" : key
                } + value ]

            [#assign multiAZ = component.MultiAZ!solnMultiAZ]
            [#local occurrenceStart = .now]
            [#list requiredOccurrences(
                getOccurrences(tier, component),
                getCLODeploymentUnit(),
                getDeploymentGroup(),
                "",
                true) as occurrence]
                [#local occurrenceEnd = .now]
                [@timing
                    message= "Got " + tier.Id + "/" + component.Id + " occurrences ..."
                    context=
                        {
                            "Elapsed" : (duration(occurrenceEnd, start)/1000)?string["0.000"],
                            "Duration" : (duration(occurrenceEnd, occurrenceStart)/1000)?string["0.000"]
                        }
                /]

                [#list occurrence.State.ResourceGroups as key,value]
                    [#if invokeComponentMacro(
                            occurrence,
                            key,
                            getCLOEntranceType(),
                            [
                                [ getCLODeploymentUnitSubset(), level  ]
                                getCLODeploymentUnitSubset(),
                                level
                            ])]

                            [@debug
                                message="Component Processing resourceGroup: " + key + "..."
                                context={
                                    "entrance" : getCLOEntranceType(),
                                    "subset" : getCLODeploymentUnitSubset(),
                                    "level" : level
                                }
                                enabled=true
                            /]
                    [/#if]
                [/#list]
                [#local processingEnd = .now]
                [@timing
                    message="Processed " + tier.Id + "/" + component.Id + "."
                    context=
                        {
                            "Elapsed"  : (duration(processingEnd, start)/1000)?string["0.000"],
                            "Duration" : (duration(processingEnd, occurrenceEnd)/1000)?string["0.000"]
                        }
                /]
            [/#list]
        [/#list]
    [/#list]
    [@timing
        message="Finished component processing."
        context=
            {
                "Elapsed"  : (duration(.now, start)/1000)?string["0.000"]
            }
        /]
[/#macro]

[#-- Get the occurrences of versions/instances of a component --]
[#function getOccurrences tier component ]
    [#return internalGetOccurrences(component, tier) ]
[/#function]

[#function getLinkTarget occurrence link activeOnly=true activeRequired=false]

    [#local instanceToMatch = internalConvertDefaultIdName(link.Instance!(getOccurrenceInstance(occurrence).Id)) ]
    [#local versionToMatch = internalConvertDefaultIdName(link.Version!(getOccurrenceVersion(occurrence).Id)) ]

    [@debug
        message="Getting link Target"
        context=
            {
                "Occurrence" : occurrence,
                "Link" : link,
                "EffectiveInstance" : instanceToMatch,
                "EffectiveVersion" : versionToMatch,
                "ActiveOnly" : activeOnly,
                "ActiveRequired" : activeRequired
            }
        enabled=false
    /]
    [#if ! (link.Enabled)!true ]
        [#return {} ]
    [/#if]

    [#-- Support LinkRefs --]
    [#if link.LinkRef?has_content]
        [#local resolvedLink =
            mergeObjects(
                (getBlueprint().LinkRefs[link.LinkRef])!{},
                getActiveLayerAttributes( ["LinkRefs", link.LinkRef], [ SOLUTION_LAYER_TYPE, PRODUCT_LAYER_TYPE, TENANT_LAYER_TYPE ] )
            )
        ]
        [#if ! resolvedLink?has_content]
            [@warning
                message="Unable to resolve linkRef " + link.LinkRef
                context=
                    mergeObjects(
                        (getBlueprint().LinkRefs)!{},
                        getActiveLayerAttributes( ["LinkRefs"], [ SOLUTION_LAYER_TYPE, PRODUCT_LAYER_TYPE, TENANT_LAYER_TYPE ] )
                    )
                detail=link
            /]
            [#return {} ]
        [/#if]
        [#return
            getLinkTarget(
                occurrence,
                mergeObjects(
                    removeObjectAttributes(link, "LinkRef"),
                    resolvedLink
                )
                activeOnly,
                activeRequired
            )
        ]
    [/#if]

    [#if ! (link.Tier?has_content && link.Component?has_content) ]
        [@fatal
            message="Link requires \"Tier\" and \"Component\" attributes"
            context=link
        /]
        [#return {} ]
    [/#if]

    [#-- Allow user defined links to specify if the link is required to be active --]
    [#if (link.ActiveRequired)?? ]
        [#local activeRequired = link.ActiveRequired ]
    [/#if]

    [#-- Grab any explicit type requirement from the link --]
    [#local linkType = link.Type!"" ]

    [#-- Handle external links --]
    [#-- They are deprecated in favour of an external tier but for now --]
    [#-- they can still be used, even with an external tier, by explicitly --]
    [#-- providing the link type --]
    [#if
        (link.Tier?lower_case == "external") &&
        (linkType?has_content || (!getTier(link.Tier)?has_content))]
        [#-- If a type is provided, ensure it has been included --]
        [#if linkType?has_content]
            [@includeComponentConfiguration linkType /]
        [/#if]
        [#return
            internalCreateOccurrenceFromExternalLink(occurrence, link) +
            {
                "Direction" : (link.Direction?lower_case)!"outbound",
                "Role" : link.Role!"external",
                "IncludeInContext" : link.IncludeInContext![]
            }
        ]
    [/#if]

    [#list getOccurrences(
                getTier(link.Tier),
                getComponent(link.Tier, link.Component)) as targetOccurrence]

        [@debug
            message="Possible link target"
            context=targetOccurrence
            enabled=false
        /]

        [#local componentType = getOccurrenceType(targetOccurrence) ]

        [#local potentialOccurrences = [targetOccurrence] ]

        [#-- Check if suboccurrence linking is required --]
        [#-- The preferred approach is to link based on the SubComponent attribute --]
        [#-- and resolve any same named subcomponents via the Type attribute       --]

        [#local subComponentId = link.SubComponent!"" ]
        [#if ! subComponentId?has_content]
            [#-- Support legacy links where subcomponent specific link attributes were used --]
            [#local subComponents = getComponentChildren(componentType) ]
            [#list subComponents as subComponent]
                [#list getComponentChildLinkAttributes(subComponent) as linkAttribute]
                    [#local subComponentId = link[linkAttribute]!"" ]
                    [#if subComponentId?has_content ]
                        [#if linkType?has_content && (linkType != subComponent.Type) ]
                            [@fatal
                                message="Link type of " + linkType + " is inconsistent with subcomponent link attribute " + linkAttribute
                                context=link
                            /]
                            [#return {} ]
                        [#else]
                            [#local linkType = subComponent.Type ]
                        [/#if]
                        [#break]
                    [/#if]
                [/#list]
                [#if subComponentId?has_content ]
                    [#break]
                [/#if]
            [/#list]
        [/#if]

        [#-- Legacy support for links to lambda without explicit function --]
        [#-- TODO(mfl): Review legacy support with view to removal --]
        [#if hasOccurrenceChildren(targetOccurrence) &&
                subComponentId == "" &&
                (componentType == LAMBDA_COMPONENT_TYPE) ]
            [#local subComponentId = (getOccurrenceChildren(targetOccurrence)[0].Core.SubComponent.Id)!"" ]
            [#local linkType = LAMBDA_FUNCTION_COMPONENT_TYPE ]
        [/#if]

        [#-- Find suboccurrences with a matching id --]
        [#if subComponentId?has_content]
            [#local potentialOccurrences = [] ]
            [#list getOccurrenceChildren(targetOccurrence) as potentialOccurrence]
                [#if
                    (subComponentId == (getOccurrenceSubComponent(potentialOccurrence).Id)!"") &&
                    (getOccurrenceInstance(potentialOccurrence).Id == instanceToMatch) &&
                    (getOccurrenceVersion(potentialOccurrence).Id == versionToMatch) &&
                    (
                        (!linkType?has_content) ||
                        (linkType == getOccurrenceType(potentialOccurrence))
                    ) ]

                    [#local potentialOccurrences += [potentialOccurrence] ]
                [/#if]
            [/#list]
            [#if potentialOccurrences?size > 1 ]
                [@fatal
                    message="Multiple matching subcomponents with id " + subComponentId + ". Use a Type attribute to differentiate them."
                    context=link
                /]
                [#return {} ]
            [/#if]
         [/#if]

        [#-- Should only be 0 or 1 array elements --]
        [#list potentialOccurrences as potentialOccurrence]

            [#-- Match needs to be exact                             --]
            [#-- If occurrences do not match, overrides can be added --]
            [#-- to the link.                                        --]
            [#if (getOccurrenceInstance(potentialOccurrence).Id != instanceToMatch) ||
                (getOccurrenceVersion(potentialOccurrence).Id != versionToMatch) ]
                [#continue]
            [/#if]

            [#-- Ensure any provided type matches - needed where subcomponent ids the same --]
            [#if linkType?has_content && (linkType != getOccurrenceType(potentialOccurrence)) ]
                [@fatal
                    message="Link type of " + linkType + " is inconsistent with matched occurrence type of " + getOccurrenceType(potentialOccurrence)
                    context=link
                /]
            [/#if]

            [@debug message="Link matched target" context=potentialOccurrence enabled=false /]

            [#-- Determine if deployed --]
            [#local isDeployed = isOccurrenceDeployed(potentialOccurrence)]

            [#-- Always warn if linking to an inactive component --]
            [#if !isDeployed && !activeRequired ]
                [@warn
                    message="link occurrence not deployed - ${occurrence.Core.Name} -> ${potentialOccurrence.Core.Name}"
                    detail="A link was made to an occurrence which has not been deployed"
                    context={
                        "Link" : link,
                        "EffectiveInstance" : instanceToMatch,
                        "EffectiveVersion" : versionToMatch
                    }
                /]
            [/#if]

            [#if ( activeOnly || activeRequired ) && !isDeployed ]
                [#if activeRequired ]
                    [@postcondition
                        function="getLinkTarget"
                        context=
                            {
                                "TargetOccurrence" : potentialOccurrence,
                                "Link" : link,
                                "EffectiveInstance" : instanceToMatch,
                                "EffectiveVersion" : versionToMatch
                            }
                        detail="HamletFatal:Link target not active/deployed. Maybe the target hasn't been deployed or there is an account mismatch?"
                        enabled=true
                    /]
                [/#if]
                [@debug message="Link matched undeployed target" enabled=false /]
                [#return {} ]
            [/#if]

            [#-- Determine the role --]
            [#local direction = (link.Direction?lower_case)!"outbound"]

            [#local role =
                link.Role!getOccurrenceDefaultRole(potentialOccurrence, direction)]

            [#return
                potentialOccurrence +
                {
                    "Direction" : direction,
                    "Role" : role,
                    "IncludeInContext" : link.IncludeInContext![]
                } ]
        [/#list]
    [/#list]

    [@postcondition
        function="getLinkTarget"
        context=
            {
                "Occurrence" : occurrence,
                "Link" : link,
                "EffectiveInstance" : instanceToMatch,
                "EffectiveVersion" : versionToMatch
            }
        detail="HamletFatal:Link not found"
    /]
    [#return {} ]
[/#function]

[#----------------------------------------------------
-- internal support functions for legacy processing --
------------------------------------------------------]

[#-- treat the value "default" for version/instance as the same as blank --]
[#function internalConvertDefaultIdName value]
    [#switch value]
        [#case "default"]
            [#return ""]
        [#default]
            [#return value]
    [/#switch]
[/#function]

[#-- Get the occurrences of versions/instances of a component           --]
[#function internalGetOccurrences component tier={} parentOccurrence={} parentContexts=[] componentType="" ]

    [#if !(component?has_content) ]
        [#return [] ]
    [/#if]

    [#local componentContexts = asArray(parentContexts) ]

    [#if tier?has_content]
        [#local type = getComponentType(component) ]
        [#local typeObject = getComponentTypeObject(component) ]
    [#else]
        [#local type = componentType ]
        [#local typeObject = component ]
    [/#if]

    [#-- Ensure we know the basic resource group information for the component --]
    [@includeSharedComponentConfiguration type /]

    [#if tier?has_content]
        [#local tierId = getTierId(tier) ]
        [#local tierName = getTierName(tier) ]
        [#local componentId = getComponentId(component) ]
        [#local componentRawId = component.Id ]
        [#local componentName = getComponentName(component) ]
        [#local componentRawName = component.Name ]
        [#local componentType = type ]
        [#local subComponentId = [] ]
        [#local subComponentRawId = [] ]
        [#local subComponentName = [] ]
        [#local subComponentRawName = [] ]
        [#local componentContexts += [component, typeObject] ]
    [#else]
        [#local tierId = parentOccurrence.Core.Tier.Id ]
        [#local tierName = parentOccurrence.Core.Tier.Name ]
        [#local componentId = parentOccurrence.Core.Component.Id ]
        [#local componentRawId = parentOccurrence.Core.Component.RawId ]
        [#local componentName = parentOccurrence.Core.Component.Name ]
        [#local componentRawName = parentOccurrence.Core.Component.RawName ]
        [#local componentType = parentOccurrence.Core.Component.Type ]
        [#local subComponentId = typeObject.Id?split("-") ]
        [#local subComponentRawId = [ typeObject.Id ] ]
        [#local subComponentName = typeObject.Name?split("-") ]
        [#local subComponentRawName = [ typeObject.Name ] ]
        [#local componentContexts += [typeObject] ]
    [/#if]

    [#local occurrences=[] ]

    [#list typeObject.Instances!{"default" : {}} as instanceKey, instanceValue]
        [#if instanceValue?is_hash ]
            [#local instance = {"Id" : instanceKey, "Name" : instanceKey} + instanceValue]
            [#local instanceId = internalConvertDefaultIdName(instance.Id) ]
            [#local instanceName = internalConvertDefaultIdName(instance.Name) ]

            [#list instance.Versions!{"default" : {}} as versionKey, versionValue]
                [#if versionValue?is_hash ]
                    [#local version = {"Id" : versionKey, "Name" : versionKey} + versionValue]
                    [#local versionId = internalConvertDefaultIdName(version.Id) ]
                    [#local versionName = internalConvertDefaultIdName(version.Name) ]
                    [#local occurrenceContexts = componentContexts + [instance, version] ]
                    [#local idExtensions =
                                subComponentId +
                                asArray(instanceId, true, true) +
                                asArray(versionId, true, true) ]
                    [#local rawIdExtensions =
                                subComponentRawId +
                                asArray(instanceId, true, true) +
                                asArray(versionId, true, true )]
                    [#local nameExtensions =
                                subComponentName +
                                asArray(instanceName, true, true) +
                                asArray(versionName, true, true)]
                    [#local rawNameExtensions =
                                subComponentRawName +
                                asArray(instanceName, true, true) +
                                asArray(versionName, true, true)]
                    [#local occurrence =
                        {
                            "Core" : {
                                "Type" : type,
                                "Tier" : {
                                    "Id" : tierId,
                                    "Name" : tierName
                                },
                                "Component" : {
                                    "Id" : componentId,
                                    "RawId" : componentRawId,
                                    "Name" : componentName,
                                    "RawName" : componentRawName,
                                    "Type" : componentType
                                },
                                "Instance" : {
                                    "Id" : firstContent(instanceId, (parentOccurrence.Core.Instance.Id)!""),
                                    "RawId" : firstContent(instance.Id, (parentOccurrence.Core.Instance.RawId)!""),
                                    "Name" : firstContent(instanceName, (parentOccurrence.Core.Instance.Name)!""),
                                    "RawName" : firstContent(instance.Name, (parentOccurrence.Core.Instance.RawName)!"")
                                },
                                "Version" : {
                                    "Id" : firstContent(versionId, (parentOccurrence.Core.Version.Id)!""),
                                    "RawId" : firstContent(version.Id, (parentOccurrence.Core.Version.RawId)!""),
                                    "Name" : firstContent(versionName, (parentOccurrence.Core.Version.Name)!""),
                                    "RawName" : firstContent(version.Name, (parentOccurrence.Core.Version.RawName)!"")
                                },
                                "Internal" : {
                                    "IdExtensions" : idExtensions,
                                    "RawIdExtensions" : rawIdExtensions,
                                    "NameExtensions" : nameExtensions,
                                    "RawNameExtensions" : rawNameExtensions
                                },
                                "Extensions" : {
                                    "Id" :
                                        ((parentOccurrence.Core.Extensions.Id)![tierId, componentId]) + idExtensions,
                                    "RawId" :
                                        ((parentOccurrence.Core.Extensions.Id)![tierId, componentRawId]) + rawIdExtensions,
                                    "Name" :
                                        ((parentOccurrence.Core.Extensions.Name)![tierName, componentName]) + nameExtensions,
                                    "RawName" :
                                        ((parentOccurrence.Core.Extensions.Name)![tierName, componentRawName]) + rawNameExtensions
                                }

                            } +
                            attributeIfContent(
                                "SubComponent",
                                subComponentId,
                                {
                                    "Id" : formatId(subComponentId),
                                    "RawId" : component.Id,
                                    "Name" : formatName(subComponentName),
                                    "RawName" : component.Name,
                                    "Type" : type
                                }
                            ),
                            "State" : {
                                "ResourceGroups" : {},
                                "Attributes" : {}
                            }
                        }
                    ]

                    [#-- check we don't already have this occurrence cached --]
                    [#-- if cached return it from cache and skip processing this occurrence --]
                    [#if isOccurrenceCached( occurrence, parentOccurrence ) ]
                        [#local occurrences += [
                            getOccurrenceFromCache( occurrence, parentOccurrence ) ]]
                        [#continue]
                    [/#if]

                    [#-- Determine the occurrence deployment and placement profiles based on normal cmdb hierarchy --]
                    [#local profiles =
                        getCompositeObject(
                            coreProfileChildConfiguration,
                            occurrenceContexts).Profiles ]

                    [#-- Determine placement profile --]
                    [#local placementProfile = getPlacementProfile(profiles.Placement) ]

                    [#-- Add resource group placements to the occurrence --]
                    [#list getComponentResourceGroups(type)?keys as key]
                        [#local occurrence =
                            mergeObjects(
                                occurrence,
                                {
                                    "State" : {
                                        "ResourceGroups" : {
                                            key : {
                                                "Placement" : getResourceGroupPlacement(key, placementProfile)
                                            }
                                        }
                                    }
                                }
                            ) ]
                    [/#list]

                    [#-- Ensure we have loaded the component configuration --]
                    [@includeComponentConfiguration
                        component=type
                        placements=occurrence.State.ResourceGroups /]

                    [#-- Determine the required attributes now the provider specific configuration is in place --]
                    [#local attributes = constructOccurrenceAttributes(occurrence) ]

                    [#-- Apply deployment and policy profile overrides                  --]
                    [#local deploymentProfile = getDeploymentProfile(profiles.Deployment, getCLODeploymentMode()) ]
                    [#local policyProfile = getPolicyProfile(profiles.Policy, getCLODeploymentMode()) ]

                    [#-- Assemble the profile objects allowing for legacy types --]
                    [#local deploymentProfileObjects = [(deploymentProfile["*"])!{}] ]
                    [#local policyProfileObjects = [(policyProfile["*"])!{}] ]
                    [#list [type] + getComponentLegacyTypes(type) as typeAlternative]
                        [#list deploymentProfile as key,value]
                            [#if  key?lower_case == typeAlternative ]
                                [#local deploymentProfileObjects += [value] ]
                            [/#if]
                        [/#list]
                        [#list policyProfile as key,value]
                            [#if  key?lower_case == typeAlternative ]
                                [#local policyProfileObjects += [value] ]
                            [/#if]
                        [/#list]
                    [/#list]


                    [#-- To allow deployment profiles to be overriden by the occurrence --]
                    [#-- configuration, use reordered occurrence contexts now that the  --]
                    [#-- deployment profiles are known                                  --]
                    [#local occurrence +=
                        {
                            "Configuration" : {
                                "Solution" :
                                    getCompositeObject(
                                        attributes,
                                        parentContexts,
                                        deploymentProfileObjects,
                                        valueIfTrue(
                                            [component, typeObject],
                                            tier?has_content,
                                            typeObject
                                        ),
                                        instance,
                                        version,
                                        policyProfileObjects
                                    )
                            }
                        }
                    ]

                    [#-- Add settings --]
                    [#local occurrence = constructOccurrenceSettings(occurrence, type) ]

                    [#-- Add state --]
                    [#local occurrence +=
                        {
                            "State" : constructOccurrenceState(occurrence, parentOccurrence)

                        } ]

                    [#-- Add suboccurrences --]
                    [#local subOccurrences = [] ]

                    [#list getComponentChildren(type) as subComponent]
                        [#-- Subcomponent instances can either be under a Components --]
                        [#-- attribute or directly under the subcomponent object.    --]
                        [#-- To cater for the latter case, any default configuration --]
                        [#-- must be under a "Configuration" attribute to avoid the  --]
                        [#-- configuration attributes being treated as subcomponent  --]
                        [#-- instances.                                              --]

                        [#-- Collect up the subcomponent configuration across the current contexts --]
                        [#local subComponentConfig =
                            (
                                getCompositeObject(
                                    [
                                        {
                                            "Names" : subComponent.Component,
                                            "Children" : [
                                                {
                                                    "Names" : "Components",
                                                    "SubObjects" : true,
                                                    "Children" : [
                                                        {
                                                            "Names" : "*"
                                                        }
                                                    ]
                                                },
                                                {
                                                    "Names" : "*"
                                                }
                                            ]
                                        }
                                    ],
                                    occurrenceContexts
                                )[subComponent.Component]
                             )!{} ]

                        [#if subComponentConfig.Components?has_content]
                            [#local subComponentInstances = subComponentConfig.Components]
                        [#else]
                            [#local subComponentInstances = removeObjectAttributes(subComponentConfig, ["Enabled", "Configured", "Components"]) ]
                        [/#if]

                        [#list subComponentInstances as key,subComponentInstance ]

                            [#if subComponentInstance?is_hash ]
                                [#local subOccurrenceContexts = occurrenceContexts ]
                                [#if (subComponentConfig.Components)?has_content ]
                                    [#-- Configuration attributes at same level as Components attribute --]
                                    [#local subOccurrenceContexts += [ removeObjectAttributes(subComponentConfig, "Components") ] ]
                                [#else]
                                    [#if key == "Configuration" ]
                                        [#-- Skip the Configuration element --]
                                        [#continue]
                                    [#else]
                                        [#-- Add in any shared configuration --]
                                        [#if subComponentConfig.Configuration?has_content]
                                            [#local subOccurrenceContexts += [ subComponentConfig.Configuration ]  ]
                                        [/#if]
                                    [/#if]
                                [/#if]
                                [#local
                                    subOccurrences +=
                                        internalGetOccurrences(
                                            {
                                                "Id" : key,
                                                "Name" : key
                                            } +
                                                subComponentInstance,
                                            {},
                                            occurrence,
                                            subOccurrenceContexts,
                                            subComponent.Type
                                        )
                                ]
                            [/#if]
                        [/#list]
                    [/#list]

                    [#local occurrence = occurrence + attributeIfContent("Occurrences", subOccurrences) ]

                    [@addOccurrenceToCache
                        occurrence=occurrence
                        parentOccurrence=parentOccurrence
                    /]

                    [#local occurrences +=
                        [
                            occurrence
                        ]
                    ]

                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#return occurrences ]
[/#function]

[#function internalCreateOccurrenceFromExternalLink occurrence link]

    [#local type = link.Type!"external" ]

    [#local targetOccurrence =
        {
            "Core" : {
                "External" : true,
                "Type" : type,
                "Tier" : {
                    "Id" : link.Tier,
                    "Name" : link.Tier
                },
                "Component" : {
                    "Id" : link.Component,
                    "Name" : link.Component
                },
                "Instance" : {
                    "Id" : "",
                    "Name" : ""
                },
                "Version" : {
                    "Id" : "",
                    "Name" : ""
                }
            },
            "Configuration" : {
                "Environment" : occurrence.Configuration.Environment
            },
            "State" : {
                "ResourceGroups" : {},
                "Attributes" : {}
            }
        }
    ]

    [#-- Determine the occurrence deployment and placement profiles based on normal cmdb hierarchy --]
    [#local profiles =
        getCompositeObject(
            coreProfileChildConfiguration).Profiles ]

    [#-- Determine placement profile --]
    [#local placementProfile = getPlacementProfile(profiles.Placement) ]

    [#-- Add state attributes for basestate lookup --]
    [#local targetOccurrence +=
        {
            "State" : constructOccurrenceState(targetOccurrence, {})

        } ]

    [#-- Add resource group placements to the occurrence --]
    [#list getComponentResourceGroups(type)?keys as key]
        [#local targetOccurrence =
            mergeObjects(
                targetOccurrence,
                {
                    "State" : {
                        "ResourceGroups" : {
                            key : {
                                "Placement" : getResourceGroupPlacement(key, placementProfile)
                            }
                        }
                    }
                }
            ) ]
    [/#list]

    [#-- Ensure we have loaded the component configuration --]
    [@includeComponentConfiguration
        component=type
        placements=targetOccurrence.State.ResourceGroups /]

    [#local targetOccurrence +=
        {
            "State" : constructOccurrenceState(targetOccurrence, {})

        } ]

    [#return targetOccurrence ]
[/#function]

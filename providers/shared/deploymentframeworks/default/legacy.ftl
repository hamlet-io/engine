[#ftl]

[#-- Redefine key directives for legacy processing --]

[#------------------------------------------
-- Public functions for legacy processing --
--------------------------------------------]

[#-- Get the occurrences of versions/instances of a component --]
[#function getOccurrences tier component ]
    [#return internalGetOccurrences(component, tier) ]
[/#function]

[#-- Main component processing loop --]
[#macro processComponents level=""]
    [#local start = .now]
    [@timing message="Starting component processing ..." /]
    [#list tiers as tier]
        [#list (tier.Components!{}) as key, value]
            [#local component =
                {
                    "Id" : key,
                    "Name" : key
                } + value ]
            [#if deploymentRequired(component, getDeploymentUnit())]
                [#assign multiAZ = component.MultiAZ!solnMultiAZ]
                [#local occurrenceStart = .now]
                [#list requiredOccurrences(
                    getOccurrences(tier, component),
                    getDeploymentUnit(),
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
                        [#switch commandLineOptions.Deployment.Unit.Subset ]
                            [#case "genplan" ]
                                [#if invokeGenPlanMacro(occurrence, key, [ level ] ) ]
                                    [@debug
                                        message="Genplan Processing key:" + key + "..."
                                        enabled=false
                                    /]
                                [/#if]
                                [#break]

                            [#default]
                                [#if invokeSetupMacro(occurrence, key, [ level ] ) ]
                                    [@debug
                                        message="Setup Processing " + key + " ..."
                                        enabled=false
                                    /]
                                [/#if]
                        [/#switch]
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
            [/#if]
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
                "EffectiveVersion" : versionToMatch
            }
        enabled=false
    /]
    [#if ! (link.Enabled)!true ]
        [#return {} ]
    [/#if]

    [#-- Handle external links --]
    [#-- They are deprecated in favour of an external tier but for now --]
    [#-- they can still be used, even with an external tier, by explicitly --]
    [#-- providing the link type --]
    [#if
        (link.Tier?lower_case == "external") &&
        (link.Type?? || (!getTier(link.Tier)?has_content))]
        [#-- If a type is provided, ensure it has been included --]
        [#if link.Type??]
            [@includeComponentConfiguration link.Type /]
        [/#if]
        [#return
            internalCreateOccurrenceFromExternalLink(occurrence, link) +
            {
                "Direction" : link.Direction!"outbound",
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

        [#local targetType = getOccurrenceType(targetOccurrence) ]

        [#local targetSubOccurrences = [targetOccurrence] ]
        [#local subComponentId = "" ]

        [#-- Check if suboccurrence linking is required --]
        [#-- Support multiple alternatives --]
        [#local subComponents = getComponentChildren(targetType) ]
        [#list subComponents as subComponent]
            [#list getComponentChildLinkAttributes(subComponent) as linkAttribute]
                [#local subComponentId = link[linkAttribute]!"" ]
                [#if subComponentId?has_content ]
                    [#break]
                [/#if]
            [/#list]
            [#if subComponentId?has_content ]
                [#break]
            [/#if]
        [/#list]

        [#-- Legacy support for links to lambda without explicit function --]
        [#-- TODO(mfl): Review legacy support with view to removal --]
        [#if hasOccurrenceChildren(targetOccurrence) &&
                subComponentId == "" &&
                (targetType == LAMBDA_COMPONENT_TYPE) ]
            [#local subComponentId = (getOccurrenceChildren(targetOccurrence)[0].Core.SubComponent.Id)!"" ]
        [/#if]

        [#if subComponentId?has_content]
            [#local targetSubOccurrences = getOccurrenceChildren(targetOccurrence) ]
        [/#if]

        [#list targetSubOccurrences as targetSubOccurrence]

            [#-- Subcomponent checking --]
            [#if subComponentId?has_content &&
                    (subComponentId != (getOccurrenceSubComponent(targetSubOccurrence).Id)!"") ]
                [#continue]
            [/#if]

            [#-- Match needs to be exact                            --]
            [#-- If occurrences do not match, overrides can be added --]
            [#-- to the link.                                       --]
            [#if (getOccurrenceInstance(targetSubOccurrence).Id != instanceToMatch) ||
                (getOccurrenceVersion(targetSubOccurrence).Id != versionToMatch) ]
                [#continue]
            [/#if]

            [@debug message="Link matched target" enabled=false /]

            [#-- Determine if deployed --]
            [#if ( activeOnly || activeRequired ) && !isOccurrenceDeployed(targetSubOccurrence) ]
                [#if activeRequired ]
                    [@postcondition
                        function="getLinkTarget"
                        context=
                            {
                                "Occurrence" : occurrence,
                                "Link" : link,
                                "EffectiveInstance" : instanceToMatch,
                                "EffectiveVersion" : versionToMatch
                            }
                        detail="COTFatal:Link target not active/deployed"
                        enabled=true
                    /]
                [/#if]
                [#return {} ]
            [/#if]

            [#-- Determine the role --]
            [#local direction = link.Direction!"outbound"]

            [#local role =
                link.Role!getOccurrenceDefaultRole(targetSubOccurrence, direction)]

            [#return
                targetSubOccurrence +
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
        detail="COTFatal:Link not found"
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
        [#local componentName = getComponentName(component) ]
        [#local subComponentId = [] ]
        [#local subComponentName = [] ]
        [#local componentContexts += [component, typeObject] ]
    [#else]
        [#local tierId = parentOccurrence.Core.Tier.Id ]
        [#local tierName = parentOccurrence.Core.Tier.Name ]
        [#local componentId = parentOccurrence.Core.Component.Id ]
        [#local componentName = parentOccurrence.Core.Component.Name ]
        [#local subComponentId = typeObject.Id?split("-") ]
        [#local subComponentName = typeObject.Name?split("-") ]
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
                    [#local nameExtensions =
                                subComponentName +
                                asArray(instanceName, true, true) +
                                asArray(versionName, true, true) ]
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
                                    "RawId" : component.Id,
                                    "Name" : componentName,
                                    "RawName" : component.Name,
                                    "Type" : type
                                },
                                "Instance" : {
                                    "Id" : firstContent(instanceId, (parentOccurrence.Core.Instance.Id)!""),
                                    "Name" : firstContent(instanceName, (parentOccurrence.Core.Instance.Name)!"")
                                },
                                "Version" : {
                                    "Id" : firstContent(versionId, (parentOccurrence.Core.Version.Id)!""),
                                    "Name" : firstContent(versionName, (parentOccurrence.Core.Version.Name)!"")
                                },
                                "Internal" : {
                                    "IdExtensions" : idExtensions,
                                    "NameExtensions" : nameExtensions
                                },
                                "Extensions" : {
                                    "Id" :
                                        ((parentOccurrence.Core.Extensions.Id)![tierId, componentId]) + idExtensions,
                                    "Name" :
                                        ((parentOccurrence.Core.Extensions.Name)![tierName, componentName]) + nameExtensions
                                }

                            } +
                            attributeIfContent(
                                "SubComponent",
                                subComponentId,
                                {
                                    "Id" : formatId(subComponentId),
                                    "Name" : formatName(subComponentName)
                                }
                            ),
                            "State" : {
                                "ResourceGroups" : {},
                                "Attributes" : {}
                            }
                        }
                    ]

                    [#-- Determine the occurrence deployment and placement profiles based on normal cmdb hierarchy --]
                    [#local profiles =
                        getCompositeObject(
                            coreProfileChildConfiguration,
                            occurrenceContexts).Profiles ]

                    [#-- Determine placement profile --]
                    [#local placementProfile = getPlacementProfile(profiles.Placement, segmentQualifiers) ]

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

                    [#-- Apply deployment profile overrides --]
                    [#local occurrenceContexts +=
                        [
                            (getDeploymentProfile(profiles.Deployment, commandLineOptions.Deployment.Mode)["*"])!{},
                            (getDeploymentProfile(profiles.Deployment, commandLineOptions.Deployment.Mode)[type])!{}
                        ]
                    ]

                    [#local occurrence +=
                        {
                            "Configuration" : {
                                "Solution" : getCompositeObject(attributes, occurrenceContexts)
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
                        [#-- configuration being treated as subcomponent instances.  --]
                        [#local subComponentInstances = {} ]
                        [#if ((typeObject[subComponent.Component])!{})?is_hash ]
                            [#local subComponentInstances =
                                (typeObject[subComponent.Component].Components)!
                                (typeObject[subComponent.Component])!{}
                            ]
                        [#else]
                            [@fatal
                              message="Subcomponent " + subComponent.Component + " content is not a hash"
                              context=typeObject[subComponent.Component] /]
                        [/#if]

                        [#list subComponentInstances as key,subComponentInstance ]
                            [#if subComponentInstance?is_hash ]
                                [#if
                                    (!((typeObject[subComponent.Component].Components)?has_content)) &&
                                    (key == "Configuration") ]
                                    [#continue]
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
                                            occurrenceContexts +
                                                [
                                                    typeObject[subComponent.Component],
                                                    typeObject[subComponent.Component].Configuration!{}
                                                ],
                                            subComponent.Type
                                        )
                                ]
                            [/#if]
                        [/#list]
                    [/#list]

                    [#local occurrences +=
                        [
                            occurrence +
                            attributeIfContent("Occurrences", subOccurrences)
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
    [#local placementProfile = getPlacementProfile(profiles.Placement, segmentQualifiers) ]

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

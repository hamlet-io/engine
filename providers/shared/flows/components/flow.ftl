[#ftl]
[#--------------------------------------------------
-- Public functions for component flow processing --
----------------------------------------------------]

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

    [#-- Formulate the effective target link --]
    [#local effectiveLink =
        link +
        {
            "Instance" : internalConvertDefaultIdName(link.Instance!(getOccurrenceInstance(occurrence).Id)),
            "Version" : internalConvertDefaultIdName(link.Version!(getOccurrenceVersion(occurrence).Id))
        }
    ]

    [@debug
        message="Getting link Target"
        context=
            {
                "Occurrence" : getOccurrenceSummary(occurrence),
                "Link" : link,
                "EffectiveLink" : effectiveLink,
                "ActiveOnly" : activeOnly,
                "ActiveRequired" : activeRequired
            }
        enabled=false
    /]

    [#-- Ignore disabled links --]
    [#if ! (link.Enabled)!true ]
        [@debug
            message="Disabled Link"
            context=link!{}
            enabled=false
        /]
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

    [#-- Determine the component type --]
    [#local component = getComponent(link.Tier, link.Component) ]
    [#local componentType = getComponentType(component) ]

    [#-- Check if suboccurrence linking is required --]
    [#-- The preferred approach is to link based on the SubComponent attribute --]
    [#-- and resolve any same named SubComponents via the Type attribute       --]

    [#local subComponentId = link.SubComponent!"" ]
    [#if ! subComponentId?has_content]
        [#-- Support legacy links where SubComponent specific link attributes were used --]
        [#local subComponents = getComponentChildren(componentType) ]
        [#list subComponents as subComponent]
            [#list getComponentChildLinkAttributes(subComponent) as linkAttribute]
                [#local subComponentId = link[linkAttribute]!"" ]
                [#if subComponentId?has_content ]
                    [#if linkType?has_content && (linkType != subComponent.Type) ]
                        [@fatal
                            message='Link type of "${linkType}" is inconsistent with SubComponent link attribute "${linkAttribute}"'
                            context=link
                        /]
                        [#return {} ]
                    [#else]
                        [#local linkType = subComponent.Type ]
                        [#local effectiveLink = removeObjectAttributes(effectiveLink, linkAttribute) ]
                    [/#if]
                    [#break]
                [/#if]
            [/#list]
            [#if subComponentId?has_content ]
                [#break]
            [/#if]
        [/#list]
    [/#if]

    [#-- Update the effective target link --]
    [#local effectiveLink +=
        attributeIfContent("SubComponent", subComponentId) +
        attributeIfContent("Type", linkType)
    ]

    [#-- Get the occurrences matching the effective link    --]
    [#-- The link is needed to prevent circular references  --]
    [#-- Because the link is included on the call, only     --]
    [#-- matches should be been returned                    --]
    [#-- A match to a component occurrence will also return --]
    [#-- any SubOccurrences. A match to a SubOccurrence     --]
    [#-- only returns the Suboccurrence itself              --]
    [#local targetOccurrences = internalGetOccurrences(component, getTier(link.Tier), effectiveLink) ]

    [#if targetOccurrences?size > 1]
        [@fatal
            message='Internal error - multiple component matches returned for component "${effectiveLink.Component}"'
            context=getOccurrenceSummary(targetOccurrences)
            detail=effectiveLink
        /]
        [#return {} ]
    [/#if]

    [#-- 0 or 1 occurrences --]
    [#list targetOccurrences as targetOccurrence]

        [#local subOccurrences = getOccurrenceChildren(targetOccurrence) ]

        [#-- Legacy support for links to lambda without explicit function --]
        [#-- Default to the first suboccurrence returned                  --]
        [#-- TODO(mfl): Review legacy support with view to removal        --]
        [#if subOccurrences?has_content &&
                effectiveLink.SubComponent == "" &&
                (getOccurrenceType(targetOccurrence) == LAMBDA_COMPONENT_TYPE) ]
            [#local effectiveLink +=
                {
                    "Type" : LAMBDA_FUNCTION_COMPONENT_TYPE,
                    "SubComponent" : (subOccurrences[0].Core.SubComponent.Id)!""
                }
            ]
            [#local matchedOccurrence = subOccurrences[0] ]
        [#else]

            [#local matchedOccurrence = targetOccurrence ]

            [#if effectiveLink.SubComponent?has_content]

                [#-- Match is to a SubComponent --]

                [#if subOccurrences?size > 1 ]
                    [@fatal
                        message='Multiple matching subcomponents with id "${effectiveLink.SubComponent}". Use a Type attribute to differentiate them.'
                        context=getOccurrenceSummary(subOccurrences)
                        detail=effectiveLink
                    /]
                    [#return {} ]
                [/#if]

                [#if subOccurrences?has_content]
                    [#local matchedOccurrence = subOccurrences[0] ]
                [#else]
                    [#-- No match --]
                    [#continue]
                [/#if]
            [/#if]
        [/#if]

        [@debug
            message="Possible link target"
            context=matchedOccurrence
            enabled=false
        /]

        [#-- Ensure any provided type matches - needed where SubComponent ids the same --]
        [#if effectiveLink.Type?has_content && (effectiveLink.Type != getOccurrenceType(matchedOccurrence)) ]
            [@fatal
                message='Link type of "${effectiveLink.Type}" is inconsistent with matched occurrence type of "${getOccurrenceType(matchedOccurrence)}"'
                context=link
            /]
        [/#if]

        [@debug message="Link matched target" context=matchedOccurrence enabled=false /]

        [#-- Determine if deployed --]
        [#local isDeployed = isOccurrenceDeployed(matchedOccurrence)]
        [#local sameDeployment = occurrencesInSameDeployment(occurrence, matchedOccurrence)]
        [#local isEnabled = (matchedOccurrence.Configuration.Solution.Enabled)!true]

        [#-- Always warn if linking to an inactive component --]
        [#if isEnabled && !sameDeployment && !isDeployed && !activeRequired ]

            [@warn
                message="Link occurrence not deployed - ${occurrence.Core.RawName} -> ${matchedOccurrence.Core.RawName}"
                detail="A link was made to an occurrence which has not been deployed"
                context={
                    "Link" : link,
                    "EffectiveLink" : effectiveLink
                }
            /]
        [/#if]

        [#if !isEnabled ]
            [@warn
                message="Link occurrence is not enabled - ${occurrence.Core.RawName} -> ${matchedOccurrence.Core.RawName}"
                detail="A link was made to an occurrence that is not enabled"
                context={
                    "Link" : link,
                    "EffectiveLink" : effectiveLink
                }
            /]
        [/#if]

        [#if ( activeOnly || activeRequired ) && !isDeployed ]
            [#if activeRequired ]
                [@postcondition
                    function="getLinkTarget"
                    context=
                        {
                            "Occurrence" : getOccurrenceSummary(occurrence),
                            "TargetOccurrence" : getOccurrenceSummary(matchedOccurrence),
                            "Link" : link,
                            "EffectiveLink" : effectiveLink
                        }
                    detail="Link target not active/deployed. Maybe the target hasn't been deployed or there is an account mismatch?"
                    enabled=true
                /]
            [/#if]
            [@debug message="Link matched undeployed target" enabled=false /]
            [#return {} ]
        [/#if]

        [#-- Determine the role --]
        [#local direction = (link.Direction?lower_case)!"outbound"]

        [#local role =
            link.Role!getOccurrenceDefaultRole(matchedOccurrence, direction)]

        [#return
            matchedOccurrence +
            {
                "Direction" : direction,
                "Role" : role,
                "IncludeInContext" : link.IncludeInContext![]
            } ]
    [/#list]

    [@postcondition
        function="getLinkTarget"
        context=
            {
                "Occurrence" : getOccurrenceSummary(occurrence),
                "Link" : link,
                "EffectiveLink" : effectiveLink
            }
        detail="Link not found"
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

[#-- Track nesting of calls to internalGetOccurrences to --]
[#-- detect loops which can occur via Locations          --]
[#assign internalGetOccurrencesInvocations = [] ]

[#--
Get the occurrences of versions/instances of a component

Occurrences are the core structure used by the hamlet
engine.

The presence of the tier parameter indicates whether
Component or SubComponent processing is required.

The function calls itself to process any
SubOccurrences. The function also indirectly call itself
when processing Locations so loop detection is
implemented to avoid stack overflows.

If a link is provided, the function will ignore any occurrence
that doesn't match the link.
--]

[#function internalGetOccurrences component tier={} link={} parentOccurrence={} parentContexts=[] componentType="" ]

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
                                        ((parentOccurrence.Core.Extensions.RawId)![tierId, componentRawId]) + rawIdExtensions,
                                    "Name" :
                                        ((parentOccurrence.Core.Extensions.Name)![tierName, componentName]) + nameExtensions,
                                    "RawName" :
                                        ((parentOccurrence.Core.Extensions.RawName)![tierName, componentRawName]) + rawNameExtensions
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


                    [#local useCache = true]
                    [#if link?has_content]
                        [#-- If a link is provided, ignore everyone except ourselves to avoid     --]
                        [#-- circular references in the case where the link is to an occurrence   --]
                        [#-- or suboccurrence of our component.                                   --]

                        [#-- The link also needs to provide a SubComponent attribute if linking   --]
                        [#-- to suboccurrences                                                    --]

                        [#if tier?has_content]
                            [#if link.SubComponent?has_content ]
                                [#-- Only use cached suboccurrences to ensure we only return matches    --]
                                [#-- The cached version of a Occurrence includes all its SubOCcurrences --]
                                [#local useCache = false]
                            [#else]
                                [#-- Occurrence targetted --]

                                [#-- Ignore everyone except ourselves --]
                                [#if
                                    (link.Tier != occurrence.Core.Tier.Id) ||
                                    (link.Component != occurrence.Core.Component.RawId) ||
                                    (link.Instance != occurrence.Core.Instance.Id) ||
                                    (link.Version != occurrence.Core.Version.Id) ||
                                    (
                                        link.Type?has_content &&
                                        (link.Type != occurrence.Core.Type)
                                    )
                                ]
                                    [#continue]
                                [/#if]
                            [/#if]
                        [#else]
                            [#if link.SubComponent?has_content ]
                                [#-- SubOccurrence targetted --]

                                [#-- Ignore ourselves --]
                                [#if
                                    (link.Tier != occurrence.Core.Tier.Id) ||
                                    (link.Component != occurrence.Core.Component.RawId) ||
                                    (link.SubComponent != occurrence.Core.SubComponent.RawId) ||
                                    (link.Instance != occurrence.Core.Instance.Id) ||
                                    (link.Version != occurrence.Core.Version.Id) ||
                                    (
                                        link.Type?has_content &&
                                        (link.Type != occurrence.Core.Type)
                                    )
                                ]
                                    [#continue]
                                [/#if]
                            [/#if]
                        [/#if]
                    [/#if]

                    [#-- Check we don't already have this occurrence cached                   --]
                    [#-- If cached, return it from cache and skip processing this occurrence  --]
                    [#-- Note this is done AFTER link processing so only matches are returned --]
                    [#-- even if coming from the cache                                        --]
                    [#if useCache && isOccurrenceCached( occurrence, parentOccurrence ) ]
                        [#local occurrences += [
                            getOccurrenceFromCache( occurrence, parentOccurrence ) ]]
                        [#continue]
                    [/#if]

                    [#-- loop detection --]

                    [#-- The Occurrence currently being visited --]
                    [#local currentInvocation =
                        {
                            "Tier" : occurrence.Core.Tier.Id,
                            "Component" : occurrence.Core.Component.RawId,
                            "SubComponent" : (occurrence.Core.SubComponent.RawId)!"",
                            "Instance" : occurrence.Core.Instance.Id,
                            "Version" : occurrence.Core.Version.Id
                        }
                    ]

                    [#-- Check for a loop --]
                    [#list internalGetOccurrencesInvocations as occurrenceInvocation]
                        [#if
                            (occurrenceInvocation.Tier == currentInvocation.Tier) &&
                            (occurrenceInvocation.Component == currentInvocation.Component) &&
                            (occurrenceInvocation.SubComponent == currentInvocation.SubComponent) &&
                            (occurrenceInvocation.Instance == currentInvocation.Instance) &&
                            (occurrenceInvocation.Version == currentInvocation.Version)
                        ]
                            [@fatal
                                message="Loop of components created via links"
                                context=internalGetOccurrencesInvocations
                                detail=currentInvocation
                            /]
                            [#return [] ]
                        [/#if]
                    [/#list]

                    [#-- Remember visiting this (sub)occurrence --]
                    [#assign internalGetOccurrencesInvocations =
                        [ currentInvocation ] +
                        internalGetOccurrencesInvocations
                    ]

                    [#-- Determine the occurrence deployment and placement profiles based on normal cmdb hierarchy --]
                    [#local profiles =
                        getCompositeObject(
                            coreProfileChildConfiguration,
                            occurrenceContexts).Profiles ]

                    [#-- Apply deployment and policy profile overrides --]
                    [#local deploymentProfile = getDeploymentProfile(profiles.Deployment, getCLODeploymentMode()) ]
                    [#local policyProfile = getPolicyProfile(profiles.Policy, getCLODeploymentMode()) ]

                    [#-- Determine placement profile --]
                    [#local placementProfile = getPlacementProfile(profiles.Placement) ]

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

                    [#-- Determine any provided location information --]
                    [#-- Permit profiles to contribute content       --]
                    [#local locations =
                        getCompositeObject(
                            [
                                {
                                    "Names" : ["placement:Locations"],
                                    "Description" : "Locations required by the component",
                                    "SubObjects" : true,
                                    "Children" : [
                                        {
                                            "Names" : "Link",
                                            "AttributeSet" : LINK_ATTRIBUTESET_TYPE,
                                            "Mandatory" : true

                                        }
                                    ]
                                }
                            ],
                            deploymentProfileObjects,
                            occurrenceContexts,
                            policyProfileObjects
                        )["placement:Locations"] ]

                    [#-- Location targets for the occurrence --]
                    [#local locationTargets = { "_config" : locations } ]

                    [#-- Add placement to each resource group          --]
                    [#-- Precedence is given to location information   --]
                    [#-- when determining placement but placement      --]
                    [#-- profiles are left for backwards compatability --]
                    [#-- until the switch to Locations is complete     --]
                    [#list getComponentResourceGroups(type)?keys as key]

                        [#local locationConfig = locations[key]!{} ]
                        [#local locationTarget = {} ]
                        [#if (locationConfig.Link)?has_content]
                            [#local locationTarget =
                                getLinkTarget(
                                    occurrence,
                                    locationConfig.Link,
                                    false,
                                    false
                                )
                            ]

                            [#if locationTarget?has_content && isOccurrenceDeployed(locationTarget)]
                                [#local locationTargets +=
                                    {
                                        key : {
                                            "Link" : locationConfig.Link,
                                            "Type" : getOccurrenceType(locationTarget),
                                            "Attributes" : getOccurrenceAttributes(locationTarget)
                                        }
                                    }
                                ]
                            [#else]
                                [#local locationTargets =
                                    combineEntities(
                                        locationTargets,
                                        {
                                            locationTarget?has_content?then("_notdeployed", "_missing") : [key]
                                        },
                                        APPEND_COMBINE_BEHAVIOUR
                                    )
                                ]
                            [/#if]
                        [/#if]

                        [#-- Use location attributes in preference to profile    --]
                        [#-- to permit a transition to location based placements --]
                        [#local profileAttributes = getResourceGroupPlacement(key, placementProfile) ]
                        [#local locationAttributes = getOccurrenceAttributes(locationTarget) ]

                        [#-- Normalise case of placement attribute names --]
                        [#local placement = {} ]
                        [#list contentIfContent(locationAttributes, profileAttributes) as attribute,value ]
                            [#switch attribute]
                                [#case "DEPLOYMENT_FRAMEWORK"]
                                [#case "DeploymentFramework"]
                                    [#local placement += { "DeploymentFramework" : value} ]
                                    [#break]
                                [#default]
                                    [#local placement += { attribute?capitalize : value } ]
                                    [#break]
                            [/#switch]
                        [/#list]

                        [#-- Ensure the minimal set of attributes required are present --]
                        [#if placement.Provider?has_content && placement.DeploymentFramework?has_content]
                            [#local occurrence =
                                mergeObjects(
                                    occurrence,
                                    {
                                        "State" : {
                                            "ResourceGroups" : {
                                                key : {
                                                    "Placement" : placement
                                                }
                                            }
                                        }
                                    }
                                ) ]
                        [#else]
                            [@fatal
                                message='Insufficient information to place resource group "${key}". Provider and DeploymentFramework are required'
                                context=getOccurrenceSummary(occurrence)
                                detail=placement
                            /]
                            [#if ! internalGetOccurrencesInvocations?has_content]
                                [@fatal
                                    message="Internal inconsistency - expecting occurrence invocation but none found (1)"
                                /]
                            [#else]
                                [#assign internalGetOccurrencesInvocations = internalGetOccurrencesInvocations[1..] ]
                            [/#if]
                            [#return [] ]
                        [/#if]
                    [/#list]

                    [#-- Ensure we have loaded the component configuration --]
                    [@includeComponentConfiguration
                        component=type
                        placements=occurrence.State.ResourceGroups /]

                    [#-- Now the provider of each resource group is known, --]
                    [#-- validate the locations according to the provider  --]
                    [#-- location requirements.                            --]
                    [#list getComponentResourceGroups(type) as key,value]

                        [#-- Determine the provider --]
                        [#local provider = occurrence.State.ResourceGroups[key].Placement.Provider!""]

                        [#-- Validate location information for provider --]
                        [#local locationsValid = true]
                        [#list getComponentResourceGroupLocations(value, provider) as location,componentLocation]

                            [#-- Determine the location target if not already found --]
                            [#local locationTarget = locationTargets[location]!{} ]
                            [#if (!locationTarget?has_content) && (location != key) ]
                                [#local locationConfig = locations[location]!{} ]
                                [#if (locationConfig.Link)?has_content]
                                    [#local locationTarget =
                                        getLinkTarget(
                                            occurrence,
                                            locationConfig.Link,
                                            false,
                                            false
                                        )
                                    ]

                                    [#if locationTarget?has_content && isOccurrenceDeployed(locationTarget)]
                                        [#local locationTargets +=
                                            {
                                                key : {
                                                    "Link" : locationConfig.Link,
                                                    "Type" : getOccurrenceType(locationTarget),
                                                    "Attributes" : getOccurrenceAttributes(locationTarget)
                                                }
                                            }
                                        ]
                                    [#else]
                                        [#local locationTargets =
                                            combineEntities(
                                                locationTargets,
                                                {
                                                    locationTarget?has_content?then("_notdeployed", "_missing") : [key]
                                                },
                                                APPEND_COMBINE_BEHAVIOUR
                                            )
                                        ]
                                    [/#if]
                                [/#if]
                            [/#if]

                            [#local targetType = (locationTargets[location].Type)!"" ]
                            [#if targetType?has_content]
                                [#-- Check the target type is what is expected --]
                                [#if ! asArray(componentLocation.TargetComponentTypes![])?seq_contains(targetType) ]
                                    [@fatal
                                        message='Target of location "${location}" does not match any of the expected types'
                                        context={
                                            "Link" : locationConfig.Link,
                                            "Expected" : componentLocation.TargetComponentTypes![],
                                            "Found" : targetType
                                        }
                                    /]
                                    [#local locationsValid = false]
                                [/#if]
                            [#else]
                                [#if componentLocation.Mandatory!true]
                                    [@fatal
                                        message='The "${key}" resource group of the "${type}" component requires a location of "${location}"'
                                    /]
                                    [#local locationsValid = false ]
                                [/#if]
                            [/#if]
                        [/#list]
                        [#if ! locationsValid ]
                            [#if ! internalGetOccurrencesInvocations?has_content]
                                [@fatal
                                    message="Internal inconsistency - expecting occurrence invocation but none found (2)"
                                /]
                            [#else]
                                [#assign internalGetOccurrencesInvocations = internalGetOccurrencesInvocations[1..] ]
                            [/#if]
                            [#return [] ]
                        [/#if]
                    [/#list]

                    [#-- Determine the required attributes now the provider specific configuration is in place --]
                    [#local attributes = constructOccurrenceAttributes(occurrence) ]

                    [#-- Determine the solution --]
                    [#local occurrence +=
                        {
                            "Configuration" : {
                                "Solution" :
                                    getCompositeObject(
                                        attributes,
                                        deploymentProfileObjects,
                                        occurrenceContexts,
                                        policyProfileObjects
                                    ),
                                "Locations" : locationTargets
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
                                            link,
                                            occurrence,
                                            subOccurrenceContexts,
                                            subComponent.Type
                                        )
                                ]
                            [/#if]
                        [/#list]
                    [/#list]

                    [#local occurrence = occurrence + attributeIfContent("Occurrences", subOccurrences) ]

                    [#-- Don't cache occurrences during link processing as they may be incomplete --]
                    [#-- due to skipped suboccurrences. It is ok to cache suboccurrences          --]
                    [#if (!link?has_content) || (!tier?has_content) ]
                        [@addOccurrenceToCache
                            occurrence=occurrence
                            parentOccurrence=parentOccurrence
                        /]
                    [/#if]

                    [#local occurrences += [ occurrence ] ]

                    [#-- Processing for this occurrence is complete --]
                    [#if ! internalGetOccurrencesInvocations?has_content]
                        [@fatal
                            message="Internal inconsistency - expecting occurrence invocation but none found (3)"
                        /]
                    [#else]
                        [#assign internalGetOccurrencesInvocations = internalGetOccurrencesInvocations[1..] ]
                    [/#if]
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

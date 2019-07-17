[#ftl]

[#-------------------------------------------
-- Public functions for context processing --
---------------------------------------------]

[#-- Contexts

A context represents a scoping boundary when performing searches for content. A
context wraps the content, but treats it as opaque.

Each context has a filter than can be used to determine if it should be
considered during a search.

Contexts are arranged hierarchically so that if a context filter does not match,
the entire subtree can be excluded from further search activity.
--]

[#function createContext type content filter={} ]
    [#return
        {
            "Type" : type?lower_case,
            "Content" : content,
            "Filter" : filter
        }]
[/#function]

[#function createChildContext type content parent={} filterAttribute=""]
    [#local filterValues = {} ]
    [#if content.Id?? || content.Name??]
        [#local filterValues =
            {
                "Id" : content.Id!content.Name,
                "Name" : content.Name!content.Id
            } ]
    [/#if]
    [#return
        createContext(
            type,
            content,
            parent.Filter +
            valueIfContent(
                {
                    contentIfContent(filterAttribute, type)?capitalize : filterValues
                },
                filterValues
            )
        ) ]
[/#function]

[#function createIntermediateContext content parent={} ]
    [#-- A context for shared content but with the filter of the parent --]
    [#return createContext("intermediate", content, parent.Filter) ]
[/#function]

[#function addChildContexts context childContexts=[] ]
    [#return
        context +
        {
            "Children" : (context.Children![]) + asArray(childContexts)
        } ]
[/#function]

[#function getContextType context]
    [#return context.Type]
[/#function]

[#function getContextContent context]
    [#return context.Content]
[/#function]

[#function getContextFilter context]
    [#return context.Filter]
[/#function]

[#-- Context hierarchies

Commonly used hierarchies

Organisation - Aggregators -> Integrators -> Tenants -> Pods
Product      - Products -> Environments -> Segments
Solution     - Solutions -> Tiers -> Components -> SubComponents
--]

[#function createRootContext content={} ]
    [#return createContext("root", content) ]
[/#function]

[#function createAggregatorContext aggregator parent={} ]
    [#return createChildContext("aggregator", aggregator, parent) ]
[/#function]

[#function createIntegratorContext integrator parent={} ]
    [#return createChildContext("integrator", integrator, parent) ]
[/#function]

[#function createTenantContext tenant parent={} ]
    [#return createChildContext("tenant", tenant, parent) ]
[/#function]

[#function createPodContext pod parent={} ]
    [#return createChildContext("pod", pod, parent) ]
[/#function]

[#function createProductContext product parent={} ]
    [#return createChildContext("product", product, parent) ]
[/#function]

[#function createEnvironmentContext environment parent={} ]
    [#return createChildContext("environment", environment, parent) ]
[/#function]

[#function createSegmentContext segment parent={} ]
    [#return createChildContext("segment", segment, parent) ]
[/#function]

[#function createSolutionContext solution parent={} ]
    [#return createIntermediateContext(solution, parent) ]
[/#function]

[#function createTierContext tier parent={} ]
    [#return createChildContext("tier", tier, parent) ]
[/#function]

[#function createComponentContext component parent={} attribute="" ]
    [#return createChildContext("component", component, parent, attribute) ]
[/#function]

[#function createInstanceContext instance parent={} ]
    [#return createChildContext("instance", instance, parent) ]
[/#function]

[#function createVersionContext version parent={} ]
    [#return createChildContext("version", version, parent) ]
[/#function]

[#function constructInstanceContexts instances parent component attribute="" ]

    [#-- Determine any child component content to pass on --]
    [#local componentChildrenAttributes = getComponentChildrenAttributes(component.Type) ]

    [#local instanceContexts = [] ]
    [#list instances!{} as instanceId, instance]
        [#if !instance?is_hash]
            [#continue]
        [/#if]
        [#local
            instanceContext =
                createInstanceContext(
                    {
                        "Id" : instanceId
                    } +
                    removeObjectAttributes(instance, ["Versions", componentChildrenAttributes]),
                    parent
                ) ]

        [#if instance.Versions?has_content]
            [#local
                instanceContexts +=
                    [
                        addChildContexts(
                            instanceContext,
                            constructVersionContexts(
                                instance.Versions,
                                instanceContext,
                                mergeObjects(
                                    component,
                                    getObjectAttributes(instance, componentChildrenAttributes)
                                ),
                                attribute
                            )
                        )
                    ] ]
        [#else]
            [#local
                instanceContexts +=
                    [
                        addChildContexts(
                            instanceContext,
                            constructComponentContext(
                                component +
                                    attributeIfContent("DeploymentUnits", instance.DeploymentUnits![]),
                                instanceContext,
                                attribute
                            )
                        )
                    ] ]
        [/#if]
    [/#list]
    [#return instanceContexts ]
[/#function]

[#function constructVersionContexts versions parent component attribute="" ]

    [#-- Determine any child component content to pass on --]
    [#local componentChildrenAttributes = getComponentChildrenAttributes(component.Type) ]

    [#local versionContexts = [] ]
    [#list versions!{} as versionId, version]
        [#if !version?is_hash]
            [#continue]
        [/#if]

        [#local
            versionContext =
                createVersionContext(
                    {
                        "Id" : versionId
                    } +
                    removeObjectAttributes(version, ["Instances", componentChildrenAttributes]),
                    parent
                ) ]

        [#if version.Instances?has_content]
            [#local
                versionContexts +=
                    [
                        addChildContexts(
                            versionContext,
                            constructInstanceContexts(
                                version.Instances,
                                versionContext,
                                mergeObjects(
                                    component,
                                    getObjectAttributes(version, componentChildrenAttributes)
                                ),
                                attribute
                            )
                        )
                    ] ]
        [#else]
            [#local
                versionContexts +=
                    [
                        addChildContexts(
                            versionContext,
                            constructComponentContext(
                                component +
                                    attributeIfContent("DeploymentUnits", version.DeploymentUnits![]),
                                versionContext,
                                attribute
                            )
                        )
                    ] ]
        [/#if]
    [/#list]
    [#return versionContexts ]
[/#function]

[#function constructComponentContext component parent={} attribute="" ]
    [#-- Determine any child component content to pass on --]
    [#local componentChildrenAttributes = getComponentChildrenAttributes(component.Type) ]

    [#-- If instance or version information, defer creation of component/subcomponent contexts --]
    [#if component.Instances?has_content || component.Versions?has_content ]

        [#-- Determine the core content to pass to instance/version --]
        [#local
            componentConfiguration =
                getObjectAttributes(
                    component,
                    ["Id", "Name", "Type"] + componentChildrenAttributes
                ) ]

        [#-- Capture configuration as an intermediate context --]
        [#local
            intermediateContext =
                createIntermediateContext(
                    removeObjectAttributes(
                        component,
                        ["Id", "Name", "Type", "Instances", "Versions"] + componentChildrenAttributes
                    ),
                    parent
                ) ]

        [#local occurrenceContexts = [] ]

        [#if component.Instances??]
            [#local occurrenceContexts +=
                constructInstanceContexts(
                    component.Instances,
                    intermediateContext,
                    componentConfiguration,
                    attribute
                ) ]
        [/#if]

        [#if component.Versions??]
            [#local occurrenceContexts +=
                constructVersionContexts(
                    component.Versions,
                    intermediateContext,
                    componentConfiguration,
                    attribute
                ) ]
        [/#if]

        [#return addChildContexts(intermediateContext, occurrenceContexts) ]
    [#else]
        [#-- Create the context for the component --]
        [#local
            componentContext =
                createComponentContext(
                    removeObjectAttributes(component, componentChildrenAttributes),
                    parent,
                    attribute
                ) ]

        [#-- Handle any child components --]
        [#local childContexts = [] ]
        [#list getComponentChildren(component.Type) as child]
            [#local childComponents = component[getComponentChildAttribute(child)]!{} ]
            [#if childComponents?has_content]
                [#list childComponents as childComponentId, childComponent]
                    [#if childComponent?is_hash]
                        [#local
                            childContexts +=
                                [
                                    constructComponentContext(
                                        {
                                            "Id" : childComponentId,
                                            "Type" : getComponentChildType(child)
                                        } + childComponent,
                                        componentContext,
                                        getComponentChildLinkAttributes(child)[0]
                                    )
                                ] ]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
        [#return addChildContexts(componentContext, childContexts) ]
    [/#if]
[/#function]

[#function constructTiersContext tiers parent={} order=[] networkOrder=[] ]
    [#local tierOrder = contentIfContent(order, tiers?keys) ]

    [#local tierContexts = [] ]
    [#list tierOrder as tierId]
        [#local tier = tiers[tierId]!{} ]
        [#-- Skip tier if nothing to process --]
        [#if !(tier.Components?has_content || ((tier.Required)!false)) ]
            [#continue]
        [/#if]

        [#if (tier.Network.Enabled)!false ]
            [#list networkOrder as networkTierId]
                [#if networkTierId == tierId]
                    [#local tier =
                        mergeObjects(
                            tier,
                            {
                                "Network" : {
                                    "Index" : networkTierId?index
                                }
                            }
                         ) ]
                    [#break]
                [/#if]
            [/#list]
        [#else]
            [#-- No network required --]
            [#local tier = mergeObjects(tier, { "Network" : {"Enabled" :false} }) ]
        [/#if]

        [#-- Components handled as separate contexts --]
        [#local
            tierContext =
                createTierContext(
                    {"Id" : tierId} + removeObjectAttributes(tier, ["Components"]),
                    parent
                ) ]
        [#local componentContexts = [] ]
        [#list tier.Components!{} as componentId, component]
            [#if component?is_hash]
                [#local componentObject = { "Id" : "componentId" } + component ]
                [#-- Determine the type specific attribute, if any --]
                [#local componentTypeAttribute = getComponentTypeObjectAttribute(componentObject) ]
                [#if componentTypeAttribute?has_content]
                    [#local
                        componentObject =
                            mergeObjects(
                                componentObject,
                                removeObjectAttributes(getComponentTypeObject(componentObject), ["Id", "Name"])
                            ) ]
                    [#local componentObject = removeObjectAttributes(componentObject, componentTypeAttribute) ]
                [/#if]

                [#local
                    componentContexts +=
                        [
                            constructComponentContext(
                                {
                                    "Type" : getComponentType(componentObject)
                                } + componentObject,
                                tierContext
                            )
                        ] ]
            [/#if]
        [/#list]
        [#local tierContexts += [addChildContexts(tierContext, componentContexts)] ]
    [/#list]
    [#return tierContexts]
[/#function]

[#-- Filters

A filter consists of one or more values for each of one or more filter attributes.
Filter comparison is a core mechanism of context processing.

When filters need to be compared, a "MatchBehaviour" attribute controls the
algorithm used. Algorithms are defined in terms of a "contextFilter" and a
"matchFilter".

The "any" behaviour requires that at least one value of the Any attribute of the
matchFilter needs to match one value in any of the attributes of the contextFilter.

The "right" behaviour requires that a value of each attribute of the matchFilter
must match a value of the same named attribute in the contextFilter, or
the attribute must be absent from the contextFilter. A variant of this is the
"inner" which requires every matchFilter attribute be present on
the contextFilter.

One way to think of filters is in terms of Venn Diagrams/SQL joins. Each filter
defines/matches a set of configuration entities and if the intersection of the
sets is not empty based on the MatchBehaviour, then the filters match.

--]

[#function createMatch filter={} type="" ]
    [#return
        {} +
        attributeIfContent("Filter", filter) +
        attributeIfContent("Type", type) ]
[/#function]

[#function getContextAsMatch context]
    [#return createMatch(context.Filter)]
[/#function]

[#assign FILTER_ANY_MATCH_BEHAVIOUR = "any"]
[#assign FILTER_RIGHT_MATCH_BEHAVIOUR = "right"]
[#assign FILTER_MINIMAL_MATCH_BEHAVIOUR = "minimal"]
[#assign FILTER_EXACT_MATCH_BEHAVIOUR = "inner"]

[#function findContexts context matches ancestors=true leafMatch=FILTER_EXACT_MATCH_BEHAVIOUR]
    [#local result = [] ]
    [#list asArray(matches) as match]
        [#local result += internalFilterContexts(context, match, ancestors, leafMatch) ]
    [/#list]
    [#return result]
[/#function]

[#function createLink filter={} direction="outbound" role="" attributes={} enabled=true]
    [#return
        {
            "Enabled" : enabled,
            "Filter" : filter,
            "Direction" : direction,
            "Attributes" : attributes
        } +
        attributeIfContent("Role", role)]

[/#function]

[#function getLinkAsMatch link]
    [#return createMatch(link.Filter)]
[/#function]

[#-- create link from simplified form --]
[#function convertSimplifiedLink link]
    [#if link.Filter?has_content]
        [#-- Already using the full format --]
        [#return link]
    [/#if]
    [#-- TODO(mfl) Remove exclusion of "Type" once external link support not needed --]
    [#return
        createLink(
            removeObjectAttributes(link, ["Direction", "Role", "Attributes", "Enabled", "Type"]),
            link.Direction!"outbound",
            link.Attributes!{},
            link.Enabled!true
        ) +
        attributeIfContent("Role", link.Role!"")
]
[/#function]

[#function removeEmptyLinkFilterAttributes link]
    [#local emptyAttributes = [] ]
    [#list link.Filter as id, value]
        [#if !value?has_content]
            [#local emptyAttributes += [id] ]
        [/#if]
    [/#list]

    [#if emptyAttributes?has_content]
        [#return
            link +
            {
                "Filter" : removeObjectAttributes(link.Filter, emptyAttributes)
            } ]
    [#else]
        [#return link]
    [/#if]
[/#function]

[#function getContextFullLink context link]

    [#-- Ensure we are dealing with the full link format --]
    [#-- Merge the context filter with the link filter --]
    [#local fullLink =
        mergeObjects(
            {
                "Filter" : context.Filter
            },
            convertSimplifiedLink(link)
        ) ]

    [#-- Remove empty attributes to permit removal of context filter attributes --]
    [#local fullLink = removeEmptyLinkFilterAttributes(fullLink) ]

    [#-- TODO(mfl) Remove when no longer using external links --]
    [#-- Support external links --]
    [#if ((fullLink.Filter.Tier)!"")?lower_case == "external"]
        [#-- Add extra attributes to link for external support --]
        [#return
            {
                "External" : true,
                "Role" : "external"
            } +
            fullLink +
            attributeIfContent("Type", link.Type!"") ]
    [/#if]

    [#return fullLink]
[/#function]

[#-----------------------------------------------------
-- Internal support functions for context processing --
-------------------------------------------------------]

[#-- Context searches

This is the core context searching mechanism which finds all matching contexts.

It returns an array of matches, each of which is an array of contexts ending
with a matching context.

--]

[#function internalGetFilterKeyValues value]
    [#return value?is_hash?then(value?values, value)]
[/#function]

[#-- A filter attribute value can be an array of strings, a string, or an object --]
[#-- If an object, then the array of object attribute values is used as the filter --]
[#-- attribute value. Note that the object attribute values are assumed to be strings --]
[#function internalFilterMatch contextFilter matchFilter matchBehaviour]

    [#switch matchBehaviour]
        [#case FILTER_ANY_MATCH_BEHAVIOUR]
            [#if !(matchFilter.Any??)]
                [#return true]
            [/#if]
            [#list contextFilter as key, value]
                [#if getArrayIntersection(
                        internalGetFilterKeyValues(value),
                        internalGetFilterKeyValues(matchFilter.Any)
                    )?has_content]
                    [#return true]
                [/#if]
            [/#list]
            [#break]

        [#case FILTER_RIGHT_MATCH_BEHAVIOUR]
        [#case FILTER_MINIMAL_MATCH_BEHAVIOUR]
            [#list matchFilter as key,value]
                [#if !(contextFilter[key]??)]
                    [#if matchBehaviour == FILTER_RIGHT_MATCH_BEHAVIOUR]
                        [#-- Treat missing attributes in the context as a match --]
                        [#continue]
                    [#else]
                        [#-- All match attributes must be present as a minimum --]
                        [#return false]
                    [/#if]
                [/#if]
                [#-- At least one value from each filter should match --]
                [#if !getArrayIntersection(
                        internalGetFilterKeyValues(contextFilter[key]),
                        internalGetFilterKeyValues(value)
                    )?has_content]
                    [#return false]
                [/#if]
            [/#list]
            [#return true]
            [#break]

        [#case FILTER_EXACT_MATCH_BEHAVIOUR]
            [#-- Should have the same number of attributes --]
            [#if contextFilter?keys?size != matchFilter?keys?size]
                [@debug
                    message="Match failure on size"
                    context=
                    {
                        "Context" : contextFilter?keys?size,
                        "Match" : matchFilter?keys?size
                    }
                    enabled=false
                /]
                [#return false]
            [/#if]
            [#list matchFilter as key,value]
                [#-- Both should have the same attributes --]
                [#if !(contextFilter[key]??)]
                    [@debug
                        message="Missing context key"
                        context=key
                        enabled=false
                    /]
                    [#return false]
                [/#if]
                [#-- At least one value from each filter should match --]
                [#if !getArrayIntersection(
                        internalGetFilterKeyValues(contextFilter[key]),
                        internalGetFilterKeyValues(value)
                    )?has_content]
                    [@debug
                        message="Match failure on key"
                        context=
                        {
                            "Key" : key,
                            "Context" : internalGetFilterKeyValues(contextFilter[key]),
                            "Match" : internalGetFilterKeyValues(value)
                        }
                        enabled=false
                    /]
                    [#return false]
                [/#if]
            [/#list]
            [#return true]
            [#break]
    [/#switch]
    [#return false]
[/#function]


[#function internalFilterContexts context match ancestors=true leafMatch=FILTER_EXACT_MATCH_BEHAVIOUR]

    [#-- Terminate the search if no potential for a more specific match --]
    [#if !internalFilterMatch(context.Filter, match.Filter, FILTER_RIGHT_MATCH_BEHAVIOUR)]
        [@debug
            message="Failed filter match"
            context=
                {
                    "Context" : context.Filter,
                    "Match" : match.Filter
                }
            enabled=false
        /]
        [#return [] ]
    [/#if]

    [#-- This context's contribution to the result --]
    [#local returnedContext = removeObjectAttributes(context, "Children")]

    [#-- Check for a more specific match on a child --]
    [#local childContent = [] ]
    [#list context.Children as child]
        [#list internalFilterContexts(child, match, ancestors, leafMatch) as childResult]
            [#-- Optionally add this context as an ancestor and return the matching children --]
            [#local childContent += [ancestors?then([returnedContext], []) + childResult] ]
        [/#list]
    [/#list]

    [#if childContent?has_content]
            [#return childContent ]
    [#else]
        [#-- No child matches so this is the last matching context --]
        [#if !internalFilterMatch(context.Filter, match.Filter, leafMatch)]
            [#-- Not an match based on the provided filter behaviour --]
            [@debug
                message="Leaf context does not match"
                context=
                    {
                        "Context" : context.Filter,
                        "Match" : match.Filter,
                        "Behaviour" : leafMatch
                    }
                enabled=false
            /]
            [#return [] ]
        [#else]
            [#return [[returnedContext]] ]
        [/#if]
    [/#if]

[/#function]


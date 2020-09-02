[#ftl]

[#-------------------------------------------
-- Public functions for context processing --
---------------------------------------------]

[#-- Filters

A filter consists of one or more values for each of one or more filter attributes.
Filter comparison is a core mechanism of context processing.

When filters need to be compared, a "FilterBehaviour" attribute controls the
algorithm used. Algorithms are defined in terms of a "contextFilter" and a
"matchFilter".

The "any" behaviour requires that at least one value of the Any attribute of the
matchFilter needs to match one value in any of the attributes of the
contextFilter for the comparison to succeed.

The "mininal" behaviour requires that a value of each attribute of the matchFilter
must match a value of the same named attribute in the contextFilter for a
successful match, or the attribute must be absent from the contextFilter.

Stricter variants of the minimal behaviour are the "subset" that requires every
matchFilter attribute be present on the contextFilter, and the "exact" that
requires the matchFilter to have the same set of attributes as the contextFilter.

A filter attribute can optionally have properties to control its processing.

--]

[#assign ANY_FILTER_BEHAVIOUR = "any"]
[#assign MINIMAL_FILTER_BEHAVIOUR = "minimal"]
[#assign SUBSET_FILTER_BEHAVIOUR = "subset"]
[#assign EXACT_FILTER_BEHAVIOUR = "exact"]

[#function addFilterAttribute filter attribute content={} properties={} ]
    [#local attributeValue = {} ]
    [#-- Extend filter with child Id/Name --]
    [#if content.Id?? || content.Name??]
        [#local attributeValue =
            {
                "Id" : content.Id!content.Name,
                "Name" : content.Name!content.Id
            } ]
    [/#if]
    [#return
        mergeObjects(
            filter,
            valueIfContent(
                {
                    attribute?cap_first : {
                        "Values" : attributeValue
                    } +
                    attributeIfContent("Properties", properties)
                },
                attributeValue
            )
        ) ]
[/#function]

[#function getFilterAttributeValues filter attribute]
    [#return (filter[attribute].Values)!filter[attribute]!{} ]
[/#function]

[#function getFilterAttributeProperties filter attribute]
    [#return (filter[attribute].Properties)!{} ]
[/#function]


[#-- Qualifiers

Qualifiers allow a nominal value to be varied based on the value of a
contextFilter.

Each qualifier has a filter and a value. The qualifier filter acts as the
matchFilter for filter comparison purposes.

Where the filter matches a contextFilter, the qualifier value is combined with
the nominal value.

More than one qualifier may match, in which case the matching qualifier values
are combined with the nominal value in the order in which the qualifiers are
defined.

The way in which the nominal and qualifier value are combined is controlled by
the "CombineBehaviour" of the qualifier.

One or more qualifiers are attached to a nominal value via a QualifiedValue object.
The qualifiers are provided via a "Qualifiers" attribute, while the nominal
value is provided by a "Value" attribute, or is the containing object minus the
"Qualifiers" attribute. Thus any object can be qualified simply by adding a
"Qualifiers" attribute.

There is a short form and a long form for qualifiers.

In the short form, the "Qualifiers" attribute value is an object, each
attribute of which represents a qualifier. The attribute key is the value of the
"Any" attribute of the matchFilter, and the FilterBehaviour is
ANY_FILTER_BEHAVIOUR.

The qualifier value is the value of the attribute. Because object attribute
processing is not ordered, the short form does not provide fine control in the
situation where multiple qualifiers match - effectively each qualifier needs
to be independent.

The short form is useful for simple situations such as setting variation based
on environment, In the following example, the nominal value is 100, but 50 will
be used assuming one attribute (e.g Environment) of the contextFilter has a
value of "prod";

{
  "Value" : 100,
  "Qualifiers" : { "prod" : 50}
}

In the long form, the "Qualifiers" attribute value is a list of qualifier
objects. Each qualifier object must have a "Filter" attribute and a "Value"
attribute, as well as optional "FilterBehaviour" and "CombineBehaviour"
attributes. By default, the FilterBehaviour is SUBSET_FILTER_BEHAVIOUR, and the
CombineBehaviour is MERGE_COMBINE_BEHAVIOUR.

The long form gives full control over the qualification process, and allows
ordering of qualifier application. The following long form example would achieve
the same as the previous short form example;

{
    "Value" : 100,
    "Qualifiers : [
        {
            "Value" : 50,
            "Filter" : {"Environment" : "prod"},
            "FilterBehaviour" : SUBSET_FILTER_BEHAVIOUR,
            "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
        }
    ]
}

Qualifiers are applied recursively.

--]

[#function getQualifiedValue entity contextFilter]

    [#if entity?is_sequence]
        [#local value = [] ]
        [#list entity as item]
            [#-- Qualify each of the items in the array --]
            [#local value += [getQualifiedValue(item, contextFilter)] ]
        [/#list]
        [#return value]
    [/#if]

    [#-- Nothing further to do if a primitive value --]
    [#if !entity?is_hash]
        [#return entity]
    [/#if]

    [#-- If not qualified, look for subqualification --]
    [#if !entity.Qualifiers?has_content]
        [#if entity.Value??]
            [#return getQualifiedValue(entity.Value, contextFilter)]
        [#else]
            [#local value = {}]
            [#list entity as key, keyValue]
                [#local value += {key, getQualifiedValue(keyValue, contextFilter)} ]
            [/#list]
            [#return value]
        [/#if]
    [/#if]

    [#local qualifiers = entity.Qualifiers]
    [#local value = entity.Value!removeObjectAttributes(entity, "Qualifiers")]

    [#if qualifiers?is_hash]
        [#list qualifiers as anyFilter,anyValue]
            [#local value =
                internalApplyQualifier(
                    contextFilter,
                    {
                        "Value" : anyValue,
                        "Filter" : {"Any" : anyFilter},
                        "FilterBehaviour" : ANY_FILTER_BEHAVIOUR,
                        "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
                    },
                    value) ]
        [/#list]
    [/#if]

    [#if qualifiers?is_sequence]
        [#list qualifiers as qualifier]
            [#if qualifier?is_hash]
                [#local value =
                    internalApplyQualifier(
                        contextFilter,
                        {
                            "FilterBehaviour" : SUBSET_FILTER_BEHAVIOUR,
                            "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
                        } + qualifier,
                        value) ]
            [/#if]
        [/#list]
    [/#if]

    [#-- Now look for lower level qualification --]
    [#return getQualifiedValue(value, contextFilter) ]
[/#function]


[#-- Contexts

A context represents a scoping boundary when performing searches for content. A
context wraps the content, but treats it as opaque.

Each context has a type and a filter that can be used to determine if it should
be considered during a search.

Contexts can be arranged hierarchically so that if a context filter does not
match, all its children can be excluded from further search activity.
--]

[#assign ROOT_CONTEXT_TYPE = "root"]
[#assign AGGREGATOR_CONTEXT_TYPE = "aggregator"]
[#assign ENTERPRISE_CONTEXT_TYPE = "enterprise"]
[#assign TENANT_CONTEXT_TYPE = "tenant"]
[#assign POD_CONTEXT_TYPE = "pod"]
[#assign PRODUCT_CONTEXT_TYPE = "product"]
[#assign ENVIRONMENT_CONTEXT_TYPE = "environment"]
[#assign SEGMENT_CONTEXT_TYPE = "segment"]
[#assign SOLUTION_CONTEXT_TYPE = "solution"]
[#assign TIER_CONTEXT_TYPE = "tier"]
[#assign COMPONENT_CONTEXT_TYPE = "component"]
[#assign INSTANCE_CONTEXT_TYPE = "instance"]
[#assign VERSION_CONTEXT_TYPE = "version"]
[#assign INTERMEDIATE_CONTEXT_TYPE = "intermediate"]

[#-- Control whether context filter attribute is merged with a link --]
[#assign IGNORE_CONTEXT_FILTER_PROPERTY = "IgnoreOnMerge"]
[#assign SUBCOMPONENT_CONTEXT_FILTER_PROPERTY = "SubComponent"]

[#-- The basics of a context object --]
[#function createContext type content filter={} intermediate=false]
    [#return
        {
            "Type" : type?lower_case,
            "Content" : content,
            "Filter" : filter
        } +
        attributeIfTrue("IsIntermediate", intermediate, true) ]
[/#function]

[#-- A context for shared content but with the filter of the parent --]
[#function createIntermediateContext content parent={} type=INTERMEDIATE_CONTEXT_TYPE]
    [#return createContext(type, content, parent.Filter, true) ]
[/#function]

[#-- A child context extends the filter of its parent --]
[#function createChildContext type content parent={} properties={} filterAttribute=""]
    [#return
        createContext(
            type,
            content,
            addFilterAttribute(
                parent.Filter,
                contentIfContent(filterAttribute, type),
                content,
                properties
            ),
            false
        ) ]
[/#function]

[#-- Support a context hierarchy --]
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

[#function isIntermediateContext context]
    [#return context.IsIntermediate]
[/#function]

[#function getContextChildren context]
    [#return context.Children![] ]
[/#function]

[#function getContextWithoutChildren context]
    [#return removeObjectAttributes(context, "Children") ]
[/#function]

[#-- A contextList is an array of contexts --]
[#function getContextByIndex contextList index]
    [#if contextList?size > index]
        [#return contextList[index] ]
    [/#if]
    [#return {} ]
[/#function]

[#-- -1 if no items --]
[#function getLastContextIndex contextList]
    [#return contextList?size - 1]
[/#function]

[#function getLastContext contextList]
    [#return getContextByIndex(contextList, getLastContextIndex(contextList))]
[/#function]

[#function contextFiltersMatch a b]
    [#return internalFilterMatch(a.Filter, b.Filter, EXACT_FILTER_BEHAVIOUR)]
[/#function]

[#-- Context hierarchies

Organisation - Aggregators -> Enterprises -> Tenants -> Pods
Product      - Products -> Environments -> Segments
Solution     - Solutions -> Tiers -> Instances -> Versions -> Components

--]

[#function createRootContext content={} ]
    [#return createContext(ROOT_CONTEXT_TYPE, content) ]
[/#function]

[#function createAggregatorContext aggregator parent={} ]
    [#return createChildContext(CONTEXT_AGGREGATOR_TYPE, aggregator, parent) ]
[/#function]

[#function createEnterpriseContext enterprise parent={} ]
    [#return createChildContext(ENTERPRISE_CONTEXT_TYPE, enterprise, parent) ]
[/#function]

[#function createTenantContext tenant parent={} ]
    [#return createChildContext(TENANT_CONTEXT_TYPE, tenant, parent) ]
[/#function]

[#function createPodContext pod parent={} ]
    [#return createChildContext(POD_CONTEXT_TYPE, pod, parent) ]
[/#function]

[#function createProductContext product parent={} ]
    [#return createChildContext(PRODUCT_CONTEXT_TYPE, product, parent) ]
[/#function]

[#function createEnvironmentContext environment parent={} ]
    [#return createChildContext(ENVIRONMENT_CONTEXT_TYPE, environment, parent) ]
[/#function]

[#function createSegmentContext segment parent={} ]
    [#return createChildContext(SEGMENT_CONTEXT_TYPE, segment, parent) ]
[/#function]

[#function createSolutionContext solution parent={} ]
    [#return createIntermediateContext(solution, parent, SOLUTION_CONTEXT_TYPE) ]
[/#function]

[#function createTierContext tier parent={} ]
    [#return createChildContext(TIER_CONTEXT_TYPE, tier, parent) ]
[/#function]

[#function createInstanceContext instance parent={} ]
    [#return createChildContext(INSTANCE_CONTEXT_TYPE, instance, parent) ]
[/#function]

[#function createVersionContext version parent={} ]
    [#return createChildContext(VERSION_CONTEXT_TYPE, version, parent) ]
[/#function]

[#function createComponentContext component parent={} attribute="" ]
    [#return createChildContext(
        COMPONENT_CONTEXT_TYPE,
        component,
        parent,
        {IGNORE_CONTEXT_FILTER_PROPERTY : true} +
        valueIfContent(
            {
                SUBCOMPONENT_CONTEXT_FILTER_PROPERTY : true
            },
            attribute
        ),
        attribute) ]
[/#function]

[#function getSubComponentFilterValues filter]
    [#list filter as key,value]
        [#if (value.Properties[SUBCOMPONENT_CONTEXT_FILTER_PROPERTY])!false]
            [#return value.Values]
        [/#if]
    [/#list]
    [#return {} ]
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
                        "Id" : instanceId,
                        "Name" : instanceId
                    } +
                    removeObjectAttributes(instance, ["DeploymentUnits", "Versions", componentChildrenAttributes]),
                    parent
                ) ]

        [#-- Occurrences of a component inherit any parent component deploymentUnit --]
        [#local componentConfiguration =
            mergeObjects(
                component + attributeIfContent("DeploymentUnits", getDeploymentUnitId(instance)),
                getObjectAttributes(instance, componentChildrenAttributes)
            ) ]

        [#-- Occurrences of a component inherit any parent component deploymentUnit --]
        [#if instance.Versions?has_content]
            [#local
                instanceContexts +=
                    [
                        addChildContexts(
                            instanceContext,
                            constructVersionContexts(
                                instance.Versions,
                                instanceContext,
                                componentConfiguration,
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
                                componentConfiguration,
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
                        "Id" : versionId,
                        "Name" : versionId
                    } +
                    removeObjectAttributes(version, ["DeploymentUnits", "Instances", componentChildrenAttributes]),
                    parent
                ) ]

        [#-- Occurrences of a component inherit any parent component deploymentUnit --]
        [#local componentConfiguration =
            mergeObjects(
                component + attributeIfContent("DeploymentUnits", getDeploymentUnitId(version)),
                getObjectAttributes(version, componentChildrenAttributes)
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
                                componentConfiguration,
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
                                componentConfiguration,
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

    [#-- First ensure the core information about the component is known --]
    [@includeSharedComponentConfiguration component=component.Type /]

    [#-- Determine any child component content to pass on --]
    [#local componentChildrenAttributes = getComponentChildrenAttributes(component.Type) ]

    [#-- If instance or version information, defer creation of component/subcomponent contexts --]
    [#if component.Instances?has_content || component.Versions?has_content ]

        [#-- Determine the core content to pass to instance/version --]
        [#local
            componentConfiguration =
                getObjectAttributes(
                    component,
                    ["Id", "Name", "Type", "DeploymentUnits"] +
                    componentChildrenAttributes
                ) ]

        [#-- Capture configuration as an intermediate context --]
        [#local
            intermediateContext =
                createIntermediateContext(
                    removeObjectAttributes(
                        component,
                        ["Id", "Name", "Type", "DeploymentUnits", "Instances", "Versions"] +
                        componentChildrenAttributes
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
        [#-- Child components inherit any parent component deploymentUnit --]
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
                                            "Name" : childComponentId,
                                            "Type" : getComponentChildType(child)
                                        } +
                                            attributeIfContent("DeploymentUnits", getDeploymentUnitId(component)) +
                                            childComponent,
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
                    {
                        "Id" : tierId,
                        "Name" : tierId
                    } + removeObjectAttributes(tier, ["Components"]),
                    parent
                ) ]
        [#local componentContexts = [] ]
        [#list tier.Components!{} as componentId, component]
            [#if component?is_hash]

                [#-- First inject a default Id/Name for the component --]
                [#local componentObject =
                    {
                        "Id" : componentId,
                        "Name" : componentId
                    } +
                    component ]

                [#-- Next inject a default type  --]
                [#local componentObject =
                    {
                        "Type" : getComponentType(componentObject)
                    } +
                    componentObject ]

                [#-- Merge in the type specific information, if any --]
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
                                componentObject,
                                tierContext
                            )
                        ] ]
            [/#if]
        [/#list]
        [#local tierContexts += [addChildContexts(tierContext, componentContexts)] ]
    [/#list]
    [#return tierContexts]
[/#function]

[#-- Matches

A match represents the criteria for a search of a context tree

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

[#function findContexts context matches ancestors=true leafMatch=EXACT_FILTER_BEHAVIOUR]
    [#local result = [] ]
    [#list asArray(matches) as match]
        [#local result += internalFilterContexts(context, match, ancestors, leafMatch) ]
    [/#list]
    [#return result]
[/#function]

[#-- Links

A link declares a directional dependency between two components.

The link filter points from a source component to a target component.
The direction of the link is relative to the source component, while the role
expresses the nature of the relationship relative to the target context.

The optional attributes provide link specific configuration for the role.

The roles available are defined as part of the state of the target component.

--]

[#assign INBOUND_LINK_DIRECTION = "inbound"]
[#assign OUTBOUND_LINK_DIRECTION = "outbound"]

[#function createLink id name filter={} direction="outbound" role="" attributes={} enabled=true]
    [#return
        {
            "Id" : id,
            "Name" : name,
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
            link.Id!"COTFatal: Id not provided on link",
            link.Name!"COTFatal: Name not provided on link",
            removeObjectAttributes(link, ["Id", "Name", "Direction", "Role", "Attributes", "Enabled", "Type"]),
            link.Direction!OUTBOUND_LINK_DIRECTION,
            link.Role!"",
            link.Attributes!{},
            link.Enabled!true
        )
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

    [#-- Ensure we are dealing with the full link format              --]
    [#-- Determine the parts of the context filter that are mergeable --]
    [#local mergeableContextFilter = {} ]
    [#list context.Filter as key,value]
        [#if !((value.Properties[IGNORE_CONTEXT_FILTER_PROPERTY])!false) ]
            [#local mergeableContextFilter += {key : value} ]
        [/#if]
    [/#list]
    [#-- Create the full link --]
    [#local fullLink =
        mergeObjects(
            {
                "Filter" : mergeableContextFilter
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


[#-- Derive effective content based on a contextList --]
[#function getContextListContent contextList contextFilter]

    [#local content = {} ]
    [#list contextList as ancestor]
        [#local content = mergeObjects(content, qualifyEntity(getContextContent(ancestor), contextFilter)) ]
    [/#list]

    [#return content]

[/#function]


[#-----------------------------------------------------
-- Internal support functions for context processing --
-------------------------------------------------------]

[#-- Qualifiers --]

[#function internalApplyQualifier contextFilter qualifier nominalValue]

    [#if internalFilterMatch(contextFilter, qualifier.Filter!{}, qualifier.FilterBehaviour) ]
        [#return combineEntities(nominalValue, qualifier.Value, qualifier.CombineBehaviour) ]
    [/#if]

    [#return nominalValue]
[/#function]

[#-- Context searches

This is the core context searching mechanism which finds all matching contexts.

It returns an array of matches, each of which is an array of contexts ending
with a matching context.

--]

[#function internalGetFilterKeyValues value]
    [#if value?is_hash]
        [#return (value.Values!value)?values]
    [/#if]
    [#return value]
[/#function]

[#-- A filter attribute value can be an array of strings, a string, or an object --]
[#-- If an object, then the array of object attribute values is used as the filter --]
[#-- attribute value. Note that the object attribute values are assumed to be strings --]
[#function internalFilterMatch contextFilter matchFilter matchBehaviour]

    [#switch matchBehaviour]
        [#case ANY_FILTER_BEHAVIOUR]
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

        [#case MINIMAL_FILTER_BEHAVIOUR]
        [#case SUBSET_FILTER_BEHAVIOUR]
            [#list matchFilter as key,value]
                [#if !(contextFilter[key]??)]
                    [#if matchBehaviour == MINIMAL_FILTER_BEHAVIOUR]
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

        [#case EXACT_FILTER_BEHAVIOUR]
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

[#-- Find matching contexts based on a matchFilter and optionally a context type       --]
[#-- Type is useful if intermediate nodes of the same type as the leaf nodes also need --]
[#-- to be processed --]
[#function internalFilterContexts context match ancestors leafMatch]

    [#-- Terminate the search if no potential for a more specific match --]
    [#if !internalFilterMatch(context.Filter, match.Filter, MINIMAL_FILTER_BEHAVIOUR)]
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
    [#local returnedContext = getContextWithoutChildren(context) ]

    [#-- Check for a more specific match on a child --]
    [#local childContent = [] ]
    [#list context.Children as child]
        [#list internalFilterContexts(child, match, ancestors, leafMatch) as childResult]
            [#-- Optionally add this context as an ancestor and return the matching children --]
            [#local childContent += [ancestors?then([returnedContext], []) + childResult] ]
        [/#list]
    [/#list]

    [#if childContent?has_content]
        [#-- Return children plus any type match --]
        [#return
            arrayIfTrue(
                [[returnedContext]],
                match.Type?? && (match.Type == context.Type)
            ) + childContent ]
    [#else]
        [#-- No child matches so this is the last matching context --]
        [#if !internalFilterMatch(context.Filter, match.Filter, leafMatch)]
            [#-- Not an match based on the provided match --]
            [@debug
                message="Leaf context does not match filter"
                context=
                    {
                        "Context" : context,
                        "Match" : match,
                        "FilterBehaviour" : leafMatch
                    }
                enabled=false
            /]
            [#return [] ]
        [/#if]
        [#if match.Type?? && (match.Type != context.Type)]
            [@debug
                message="Leaf context does not match type"
                context=
                    {
                        "Context" : context,
                        "Match" : match
                    }
                enabled=false
            /]
            [#return [] ]
        [/#if]
    [/#if]
    [#return [[returnedContext]] ]
[/#function]

[#ftl]

[#-------------------------------------------
-- Public functions for context processing --
---------------------------------------------]

[#-- Filters

A filter consists of one or more values for each of one or more filter attributes.
Filter comparison is a core mechanism of context processing.

When filters need to be compared, a "MatchBehaviour" attribute controls the
algorithm used. Algorithms are defined in terms of a "contextFilter" and a
"matchFilter".

The "any" behaviour requires that at least one value of the Any attribute of the
matchFilter needs to match one value in any of the attributes of the contextFilter.

The "onetoone" behaviour requires that a value of each attribute of the matchFilter
must match a value of the same named attribute in the contextFilter, or
the attribute must be absent from the contextFilter. A variant of this is the
"exclusive onetoone" which requires every matchFilter attribute be present on
the contextFilter.

One way to think of filters is in terms of Venn Diagrams. Each filter
defines/matches a set of configuration entities and if the intersection of the
sets is not empty based on the MatchBehaviour, then the filters match.

--]

[#assign FILTER_ANY_MATCH_BEHAVIOUR = "any"]
[#assign FILTER_ONETOONE_MATCH_BEHAVIOUR = "onetoone"]
[#assign FILTER_EXCLUSIVE_ONETOONE_MATCH_BEHAVIOUR = "exclusive"]

[#function filterMatch contextFilter matchFilter matchBehaviour]

    [#switch matchBehaviour]
        [#case FILTER_ANY_MATCH_BEHAVIOUR]
            [#if !(matchFilter.Any??)]
                [#return true]
            [/#if]
            [#list contextFilter as key, value]
                [#if getArrayIntersection(value, matchFilter.Any)?has_content]
                    [#return true]
                [/#if]
            [/#list]
            [#break]

        [#case FILTER_ONETOONE_MATCH_BEHAVIOUR]
            [#list matchFilter as key,value]
                [#if !(contextFilter.key??)]
                    [#continue]
                [/#if]
                [#if !getArrayIntersection(contextFilter.key,value)?has_content]
                    [#return false]
                [/#if]
            [/#list]
            [#return true]
            [#break]

        [#case EXCLUSIVE_FILTER_ONETOONE_MATCH_BEHAVIOUR]
            [#list matchFilter as key,value]
                [#if !(contextFilter.key??)]
                    [#return false]
                [/#if]
                [#if !getArrayIntersection(contextFilter.key,value)?has_content]
                    [#return false]
                [/#if]
            [/#list]
            [#return true]
            [#break]
    [/#switch]
    [#return false]
[/#function]

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
    [#local filterValues = [] ]
    [#if content.Id??]
        [#local filterValues += [content.Id] ]
    [/#if]
    [#if content.Name??]
        [#local filterValues += [content.Name] ]
    [/#if]
    [#return
        createContext(
            type,
            content,
            parent.Filter +
            valueIfContent(
                {
                    contentIfContent(filterAttribute, type)?capitalize :
                        getUniqueArrayElements(filterValues)
                },
                filterValues
            )
        ) ]
[/#function]

[#function addChildContexts context childContexts=[] ]
    [#return
        context +
        {
            "Children" : (context.Children![]) + childContexts
        } ]
[/#function]

[#-- Context hierarchies

Commonly used hierarchies

Organisation - Aggregators -> Integrators -> Tenants -> Pods
Product      - Products -> Environments -> Segments
Solution     - Solutions -> Tiers -> Components -> SubComponents
--]

[#function createRootContext content={} ]
    [#return createContext("root", content)]
[/#function]

[#function createAggregatorContext aggregator parent={} ]
    [#return createChildContext("aggregator", aggregator, parent)]
[/#function]

[#function createIntegratorContext integrator parent={} ]
    [#return createChildContext("integrator", integrator, parent)]
[/#function]

[#function createTenantContext tenant parent={} ]
    [#return createChildContext("tenant", tenant, parent)]
[/#function]

[#function createPodContext pod parent={} ]
    [#return createChildContext("pod", removeObjectAttributes(pod, ["Order", "Tiers"]), parent)]
[/#function]

[#function createProductContext product parent={} ]
    [#return createChildContext("product", product, parent)]
[/#function]

[#function createEnvironmentContext environment parent={} ]
    [#return createChildContext("environment", environment, parent)]
[/#function]

[#function createSegmentContext segment parent={} ]
    [#return createChildContext("segment", segment, parent)]
[/#function]

[#function createSolutionContext parent={} ]
    [#-- Solution has same filter as parent, but allows for a solution level ancestor --]
    [#return createChildContext("solution", {}, parent)]
[/#function]

[#function createTierContext tier parent={} ]
    [#return createChildContext("tier", removeObjectAttributes(tier, "Components"), parent)]
[/#function]

[#function createComponentContext component parent={} attribute="" ]
    [#return createChildContext("component", component, parent, attribute)]
[/#function]

[#function getContextContent context]
    [#return context.Content]
[/#function]

[#-- Context searches

This is the core context searching mechanism which returns as an array the
contents of all matching contexts.

--]

[#function filterContexts context matchFilter ancestors=true exclusive=true]

    [#-- Terminate the search if no potential for a more specific match --]
    [#if !filterMatch(context.Filter, matchFilter, FILTER_ONETOONE_MATCH_BEHAVIOUR)]
        [#return [] ]
    [/#if]

    [#-- Check for a more specific match on a child --]
    [#local childContent = [] ]
    [#list context.Children as child]
        [#local childContent += filterContexts(child, matchFilter, ancestors, exclusive)]
    [/#list]

    [#if childContent?has_content]
        [#-- Optionally add this context as an ancestor and return the matching children --]
        [return ancestors?then(context.Content, []) + childContent]
    [#else]
        [#-- No child matches so this is the last matching context --]
        [#if exclusive &&
            (!filterMatch(context.Filter, matchFilter, FILTER_EXCLUSIVE_ONETOONE_MATCH_BEHAVIOUR))]
            [#-- Not an exclusive match --]
            [#return [] ]
        [#else]
            [#return context.Content]
        [/#if]
    [/#if]
[/#function]

[#-----------------------------------------------------
-- Internal support functions for context processing --
-------------------------------------------------------]

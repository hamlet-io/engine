[#ftl]

[#-- Build the context tree corresponding to the provided config --]
[#function default_model args=[] ]

    [#local pods =
        {
            "PodOrder" : ["default"],
            "Pods" : {
                "default" : {
                    "Solution" : {
                        "TierOrder" : ["region", "account"],
                        "Tiers" : {
                            "region" : {
                                "Components" : {
                                    regionId :
                                        {
                                            "Type" : "region"
                                        } + regionObject
                                }
                            },
                            "account" : {
                                "Components" : {
                                    accountId :
                                        {
                                            "Type" : "account"
                                        } + accountObject
                                }
                            }
                        }
                    }
                }
            }
        } ]

    [#local rootContext = createRootContext() ]

    [#local tenantContexts = [] ]
    [#list tenants as tenantId, tenant]
        [#local tenantContext =
            createTenantContext(
                {
                    "Id" : tenantId,
                    "Name" : tenantId
                } + tenant,
                rootContext)]

        [#local podContexts = [] ]
        [#list pods.PodOrder as podId]
            [#local pod = pods.Pods[podId] ]
            [#local podContext =
                createPodContext(
                    {
                        "Id" : podId,
                        "Name" : podId
                    } + removeObjectAttributes(pod, "Solution"),
                    tenantContext
                ) ]
            [#local solutionContext = createSolutionContext({}, podContext) ]
            [#local solutionContext =
                addChildContexts(
                    solutionContext,
                    constructTiersContext(
                        pod.Solution.Tiers!{},
                        solutionContext,
                        pod.Solution.TierOrder![]
                    )
                ) ]
            [#local podContexts += [addChildContexts(podContext, solutionContext)] ]
        [/#list]

        [#local productContexts = [] ]
        [#list arrayIfContent(productObject!{}, productObject!{}) as product]
            [#local productContext = createProductContext(product, tenantContext)]
            [#local environmentContexts = [] ]
            [#list arrayIfContent(environmentObject!{}, environmentObject!{}) as environment]
                [#local environmentContext = createEnvironmentContext(environment, productContext)]
                [#local segmentContexts = [] ]
                [#list arrayIfContent(segmentObject!{}, segmentObject!{}) as segment]
                    [#local segmentContext = createSegmentContext(segment, environmentContext)]
                    [#local solutionContext = createSolutionContext(solutionObject, segmentContext) ]
                    [#local solutionContext =
                        [
                            addChildContexts(
                                solutionContext,
                                constructTiersContext(
                                    removeObjectAttributes(blueprintObject.Tiers, ["Id", "Name"]),
                                    solutionContext,
                                    segmentObject.Tiers.Order![],
                                    segmentObject.Network.Tiers.Order![]
                                )
                            )
                        ] ]
                    [#local segmentContexts +=
                        [
                            addChildContexts(segmentContext, solutionContext)
                        ] ]
                [/#list]
                [#local environmentContexts += [addChildContexts(environmentContext, segmentContexts)] ]
            [/#list]
            [#local productContexts += [addChildContexts(productContext, environmentContexts)] ]
        [/#list]

        [#local tenantContexts += [addChildContexts(tenantContext, podContexts + productContexts)] ]
    [/#list]

    [#return addChildContexts(rootContext, tenantContexts)]
    [#-- assign model = addChildContexts(rootContext, tenantContexts) --]
[/#function]

[#function createOccurrenceFromContext context]
    [#return {"State" : {"ResourceGroups" : {}}} ]
[/#function]

[#function createOccurrenceFromContextExternalLink occurrence fullLink]
    [#return {} ]
[/#function]

[#function getContextLinkTarget occurrence link activeOnly=true activeRequired=false]

    [#local fullLink = getContextFullLink(occurrence.Context, link)]

    [@debug
        message="Getting link Target"
        context=
            {
                "Context" : occurrence,
                "Link" : link,
                "FullLink" : fullLink
            }
        enabled=false
    /]

    [#if !fullLink.Enabled ]
        [#return {} ]
    [/#if]

    [#-- TODO(mfl) remove when external link support superceded by external components --]
    [#if fullLink.External!false]
        [#-- If a type is provided, ensure it has been included --]
        [#if fullLink.Type??]
            [@includeComponentConfiguration fullLink.Type /]
        [/#if]
        [#return
            createOccurrenceFromContextExternalLink(occurrence, link) +
            {
                "Direction" : fullLink.Direction,
                "Role" : fullLink.Role
            }
        ]
    [/#if]

    [#-- NOTE: Filter must contain all relevant attributes In particular, links            --]
    [#-- to lambda functions much contain the function attribute even if only one function --]
    [#local targetContexts = findContexts(model, getLinkAsMatch(fullLink)) ]

    [#if targetContexts?size > 1]
        [@fatal
            message="Link matched multiple targets"
            context=targetContexts
        /]
        [#return {} ]
    [/#if]

    [#if targetContexts?has_content]
        [@debug
            message="Link matched target"
            context=targetContexts[0]
            enabled=false
        /]

        [#local targetOccurrence = createOccurrenceFromContext(targetContexts[0])]

        [#-- Determine if deployed --]
        [#if ( activeOnly || activeRequired ) && !isOccurrenceDeployed(targetOccurrence) ]
            [#if activeRequired ]
                [@postcondition
                    function="getContextLinkTarget"
                    context=
                        {
                            "Occurrence" : occurrence,
                            "Link" : link,
                            "FullLink" : fullLink
                        }
                    detail="COTFatal:Link target not active/deployed"
                    enabled=true
                /]
            [/#if]
            [#return {} ]
        [/#if]

        [#-- Determine the role --]
        [#local role =
            fullLink.Role!getOccurrenceDefaultRole(targetOccurrence, fullLink.Direction)]

        [#return
            targetOccurrence +
            {
                "Direction" : fullLink.Direction,
                "Role" : role
            } ]
    [/#if]

    [@postcondition
        function="getContextLinkTarget"
        context=
            {
                "Occurrence" : occurrence,
                "Link" : link,
                "FullLink" : fullLink
            }
        detail="COTFatal:Link not found"
    /]
    [#return {} ]
[/#function]

[#function findDeploymentUnitContexts contexts deploymentUnit]
    [#local result = [] ]

    [#-- Look for the deployment unit in the content of the leaf node --]
    [#list asArray(contexts) as context]
        [@debug
            message="Checking context"
            context=context
            enabled=false
        /]
        [#if asArray((getContextContent(context[context?size - 1]).DeploymentUnits)![])?seq_contains(deploymentUnit) ]
            [#local result += [context] ]
            [@debug
                message="Found deployment unit match"
                context=context
                enabled=false
            /]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#macro processContexts matches level="" matchWithAncestors=false]
    [#local start = .now]
    [@timing
        message="Starting context processing ..."
        context=matches
    /]

    [#-- Find matches, optionally including their ancestors --]
    [#local contexts =
        findDeploymentUnitContexts(
            findContexts(
                model,
                matches,
                matchWithAncestors,
                FILTER_MINIMAL_MATCH_BEHAVIOUR
            ),
            deploymentUnit
        ) ]

    [@timing
        message=
            "Identified contexts, took " + (duration(.now, start)/1000)?string["0.000"]
    /]

    [#list contexts as context]
        [#local processingStart = .now]

        [@debug
            message="Processing context ..."
            context=context
            enabled=true
        /]

        [#-- Not sure whether its quicker to get ancestors during matching --]
        [#if matchWithAncestors]
            [#-- Create the occurrence structure --]
            [#local occurrence = createOccurrenceFromContext(context) ]
        [#else]
            [#-- collect the ancestors --]
            [#local occurrence =
                createOccurrenceFromContext(
                    findContexts(
                        model,
                        getContextAsMatch(context[context?size -1])
                    )[0]
                ) ]
        [/#if]

        [@debug
            message="Generated occurrence ..."
            context=occurrence
            enabled=true
        /]

        [#-- Process each resource group --]
        [#list occurrence.State.ResourceGroups as key,value]
            [#if invokeSetupMacro(occurrence, key, ["setup", level]) ]
                [@debug
                    message="Processing resource group " + key + " ..."
                    enabled=false
                /]
            [/#if]
        [/#list]

        [#local processingEnd = .now]
        [@timing
            message=
                "Processed context, took " +
                (duration(processingEnd, processingStart)/1000)?string["0.000"] + ", " +
                (duration(processingEnd, start)/1000)?string["0.000"] + " elapsed"
        /]
    [/#list]
    [@timing
        message=
            "Finished context processing, took " +
            (duration(.now, start)/1000)?string["0.000"]
    /]
[/#macro]


[#-- Override the legacy occurrence/link support --]
[#function getLinkTarget occurrence link activeOnly=true activeRequired=false]
    [#return getContextLinkTarget(occurrence,link activeOnly, activeRequired) ]
[/#function]

[#macro processComponents level=""]

    [#-- Construct the match corresponding to provided values --]
    [#-- This can later be provided as an explicit parameter  --]
    [#local match =
        createMatch(
            {} +
            attributeIfContent("Tenant", tenantId!"") +
            attributeIfContent("Product", productId!"") +
            attributeIfContent("Environment", environmentId!"") +
            attributeIfContent("Segment", segmentId!"")
        ) ]

    [@processContexts matches=match level=level /]
[/#macro]


[#---------------------------------
-- Support for legacy processing --
-----------------------------------]

[#-- Nothing to do here --]
[#function default_model_legacy args=[] ]
    [#return {} ]
[/#function]

[#if (deploymentFrameworkModel!"")?lower_case == "legacy"]
    [#include "legacy.ftl" ]
[/#if]

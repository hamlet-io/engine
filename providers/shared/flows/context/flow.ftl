[#ftl]

[#-------------------------------------------------------
-- Public functions for context based flow processing --
---------------------------------------------------------]

[#-- Main component processing loop --]
[#macro default_flow_context level=""]

    [#include "context.ftl"]
    [#-- Construct the match corresponding to provided values --]
    [#-- This can later be provided as an explicit parameter  --]
    [#local match =
        createMatch(
            {} +
            attributeIfContent("Tenant", tenantId!"") +
            attributeIfContent("Product", productId!"") +
            attributeIfContent("Environment", environmentId!"") +
            attributeIfContent("Segment", segmentId!""),
            COMPONENT_CONTEXT_TYPE
        ) ]

    [@internalProcessContexts matches=match level=level /]
[/#macro]

[#-----------------------------------------------------------------
-- Internal support functions for context based model processing --
-------------------------------------------------------------------]

[#function internalDefaultModel args ]
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
[/#function]

[#function internalFindDeploymentUnitContexts contextLists deploymentUnit]
    [#local result = [] ]

    [#-- Look for the deployment unit in the content of the leaf node --]
    [#list asArray(contextLists) as contextList]
        [@debug
            message="Checking context list"
            context=contextList
            enabled=false
        /]
        [#if asArray((getContextContent(getLastContext(contextList)).DeploymentUnits)![])?seq_contains(deploymentUnit) ]
            [#local result += [contextList] ]
            [@debug
                message="Found deployment unit match"
                context=contextList
                enabled=false
            /]
        [/#if]
    [/#list]
    [#return result]
[/#function]


[#macro internalProcessContexts matches level=""]
    [#local start = .now]
    [@timing
        message="Starting context processing ..."
        context=matches
    /]

    [#local model = internalDefaultModel(args)]
    [#-- Find matches including their ancestors --]
    [#local contextLists =
        internalFindDeploymentUnitContexts(
            findContexts(
                model,
                matches,
                true,
                MINIMAL_FILTER_BEHAVIOUR
            ),
            getCLODeploymentUnit()
        ) ]

    [@debug
        message="Processing context lists ..."
        context=contextLists
        enabled=false
    /]

    [@timing
        message=
            "Identified contexts, took " + (duration(.now, start)/1000)?string["0.000"]
    /]

    [#list contextLists as contextList]
        [#local processingStart = .now]

        [@debug
            message="Processing context list ..."
            context=contextList
            enabled=false
        /]

        [#-- Find the context family --]
        [#local family =
                internalFindContextFamily(
                    contextList,
                    splitArray(contextLists, contextList?index + 1)
                ) ]

        [@debug
            message="Processing context family ..."
            context=family
            enabled=false
        /]

        [#-- Find the context family and create the occurrence structure --]
        [#-- This supports a few patterns with suboccurrences.           --]
        [#-- 1) parent deals with the generation of the children         --]
        [#-- 2) children have their own setup template but no deployment --]
        [#--    unit so inherit their parent's                           --]
        [#-- 3) children have their own setup template and deployment    --]
        [#--    so are ignored as part of parent processing              --]
        [#local occurrence = internalCreateOccurrenceFromContextLists(family) ]

        [@debug
            message="Generated occurrence ..."
            context=occurrence
            enabled=false
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

[#-- Find parent/child combinations --]
[#function internalFindContextFamily contextList candidateContextLists]
    [#-- Always return at least one contextlist --]
    [#local result = [contextList] ]

    [#-- Check for candidates with the same context at the same position --]
    [#local leafIndex = getLastContextIndex(contextList)]
    [#local leaf = getLastContext(contextList)]

    [#list candidateContextLists as candidate]
        [#-- Ignore if candidate can't contain parent --]
        [#if candidate?size <= contextList?size]
            [#continue]
        [/#if]

        [#-- Get the equivalent candidate context to the parent context --]
        [#local candidateContext = getContextByIndex(candidate, leafIndex)]
        [#if !candidateContext?has_content]
            [#continue]
        [/#if]

        [#-- Ignore if not the same parent --]
        [#if !contextFiltersMatch(leaf, candidateContext)]
            [#continue]
        [/#if]

        [#-- Remember subContextList --]
        [#local result += [candidate]]
    [/#list]

    [#return result]
[/#function]

[#-- Create occurrence with subOccurrences --]
[#function internalCreateOccurrenceFromContextLists contextLists=[] ]

    [#-- First create the occurrence --]
    [#local occurrence = internalCreateOccurrenceFromContextList(contextLists[0])]

    [#-- Now any subOccurrences --]
    [#local subOccurrences = [] ]
    [#list splitArray(contextLists, 1) as contextList]
        [#local subOccurrence = internalCreateOccurrenceFromContextList(contextList) ]
        [@debug
            message="Generated suboccurrence ..."
            context=subOccurrence
            enabled=false
        /]
        [#local subOccurrences += [subOccurrence] ]
    [/#list]

    [#return occurrence + {"Occurrences" : subOccurrences} ]
[/#function]


[#-- Process any component contexts in turn --]
[#-- SubOccurrences will be empty --]
[#function internalCreateOccurrenceFromContextList contextList ]

    [#local result = {} ]
    [#list contextList as context ]
        [#if context.Type != COMPONENT_CONTEXT_TYPE]
            [#continue]
        [/#if]
        [#local result = internalCreateContextOccurrence(result, contextList[0..context?index])]
    [/#list]

    [#return result]
[/#function]

[#function internalGetOccurrenceIdOrName value]
    [#return (value == "default")?then("", value) ]
[/#function]

[#-- Construct occurrence --]
[#function internalCreateContextOccurrence parentOccurrence contextList ]

    [#-- Get the leaf context  --]
    [#local leaf = getLastContext(contextList) ]
    [#local filter = getContextFilter(leaf) ]

    [#-- Get the effective content (inherited and qualified) --]
    [#local content = getContextListContent(contextList, filter) ]

    [#-- Ensure we know the basic resource group information for the component --]
    [#local type = content.Type ]
    [@includeSharedComponentConfiguration type /]

    [#-- Get tier Id/Name --]
    [#local tierId = getFilterAttributeValues(filter, "Tier").Id]
    [#local tierName = getFilterAttributeValues(filter, "Tier").Name]

    [#-- Strip off any type info in the component id/name --]
    [#local componentId = getComponentId(getFilterAttributeValues(filter, "Component").Id) ]
    [#local componentName = getComponentName(getFilterAttributeValues(filter, "Component").Name) ]

    [#-- Determine parent instance/version --]
    [#local parentInstanceId = (parentOccurrence.Core.Instance.Id)!""]
    [#local parentInstanceName = (parentOccurrence.Core.Instance.Name)!""]
    [#local parentVersionId = (parentOccurrence.Core.Version.Id)!""]
    [#local parentVersionName = (parentOccurrence.Core.Version.Name)!""]

    [#-- Determine instance/version values --]
    [#-- Ignore if already defined for parent --]
    [#local instanceId =
        valueIfContent(
            "",
            parentInstanceId,
            internalGetOccurrenceIdOrName((getFilterAttributeValues(filter, "Instance").Id)!"")
        ) ]
    [#local instanceName =
        valueIfContent(
            "",
            parentInstanceName,
            internalGetOccurrenceIdOrName((getFilterAttributeValues(filter, "Instance").Name)!"")
        ) ]
    [#local versionId =
        valueIfContent(
            "",
            parentVersionId,
            internalGetOccurrenceIdOrName((getFilterAttributeValues(filter, "Version").Id)!"")
        ) ]
    [#local versionName =
        valueIfContent(
            "",
            parentVersionName,
            internalGetOccurrenceIdOrName((getFilterAttributeValues(filter, "Version").Name)!"")
        ) ]

    [#-- Determine any subcomponent id/name              --]
    [#-- The filter contains the specific link attribute --]
    [#local subComponent = {} ]
    [#local subComponentIdParts = [] ]
    [#local subComponentNameParts = [] ]

    [#local subComponentFilterValues = getSubComponentFilterValues(filter)]
    [#if subComponentFilterValues?has_content]
        [#local subComponentIdParts = subComponentFilterValues.Id?split("-") ]
        [#local subComponentNameParts = subComponentFilterValues.Name?split("-") ]
        [#local subComponent =
            {
                "Id" : formatId(subComponentIdParts),
                "Name" : formatName(subComponentNameParts)
            } ]
    [/#if]

    [#-- Capture core information from the leaf context          --]
    [#-- asArray use on extensions ignored empty values          --]
    [#local occurrence =
        {
            "Context" : leaf,
            "Core" : {
                "Type" : type,
                "Tier" : {
                    "Id" : tierId,
                    "Name" : tierName
                },
                "Component" : {
                    "Id" : componentId,
                    "RawId" : getFilterAttributeValues(filter, "Component").Id,
                    "Name" : componentName,
                    "RawName" : getFilterAttributeValues(filter, "Component").Name,
                    "Type" : type
                },
                "Instance" : {
                    "Id" : firstContent(parentInstanceId, instanceId),
                    "Name" : firstContent(parentInstanceName, instanceName)
                },
                "Version" : {
                    "Id" : firstContent(parentVersionId, versionId),
                    "Name" : firstContent(parentVersionName, versionName)
                },
                "Internal" : {
                    "IdExtensions" :
                        asArray(
                            [
                                subComponentIdParts,
                                instanceId,
                                instanceName
                            ],
                            true,
                            true
                        ),
                    "NameExtensions" :
                        asArray(
                            [
                                subComponentNameParts,
                                instanceName,
                                versionName
                            ],
                            true,
                            true
                        )
                },
                "Extensions" : {
                    "Id" :
                        asArray(
                            [
                                tierId,
                                componentId
                                parentInstanceId,
                                parentVersionId,
                                subComponentIdParts,
                                instanceId,
                                versionId
                            ],
                            true,
                            true
                        ),
                    "Name" :
                        asArray(
                            [
                                tierName,
                                componentName,
                                parentInstanceName,
                                parentVersionName,
                                subComponentNameParts,
                                instanceName,
                                versionName
                            ],
                            true,
                            true
                        )
                }
            } +
            attributeIfContent("SubComponent", subComponent),
            "State" : {
                "ResourceGroups" : {},
                "Attributes" : {}
            },
            "Occurrences" : []
        } ]

    [#-- Determine the occurrence deployment and placement profiles based on normal cmdb hierarchy --]
    [#local profiles = getCompositeObject(coreProfileChildConfiguration, content).Profiles ]

    [#-- Determine placement profile --]
    [#local placementProfile = placementProfiles[profiles.Placement]!{} ]

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

    [#local occurrence +=
        {
            "Configuration" : {
                "Solution" :
                    getCompositeObject(
                        attributes,
                        [
                            content,
                            (getDeploymentProfile(profiles.Deployment, getCLODeploymentMode())["*"])!{},
                            (getDeploymentProfile(profiles.Deployment, getCLODeploymentMode())[type])!{}
                        ])
            }
        }
    ]

    [#-- Add settings --]
    [#local occurrence = constructOccurrenceSettings(occurrence, type) ]

    [#-- Add state --]
    [#return
        occurrence +
        {
            "State" : constructOccurrenceState(occurrence, parentOccurrence)
        } ]
[/#function]

[#function internalCreateOccurrenceFromContextExternalLink occurrence fullLink]
    [#return {} ]
[/#function]

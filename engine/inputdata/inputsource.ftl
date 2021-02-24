[#ftl]

[#-----------------------------------------
-- Public functions for input processing --
-------------------------------------------]

[#-- No input state changes on startup --]
[#assign inputStateStack = initialiseStack() ]

[#-- initialise input processing - must be called first --]
[#macro initialiseInputProcessing inputSource inputFilter ]

    [#-- Current input state --]
    [#assign inputState = {} ]

    [#-- Stack of input state changes --]
    [#assign inputStateStack = initialiseStack() ]
    [#assign inputStateStackHistory = [] ]

    [#-- Cache of input states --]
    [#assign inputStateCache = [] ]

    [@pushInputSource
        inputSource=inputSource
        inputFilter=inputFilter
    /]

[/#macro]

[#-- Manage the set of known input sources --]

[#--
An input source provides state to the engine. It relies on one
or more stages to provide content. Stages are dynamically ordered
based on priority so it is possible to insert new stages into
the existing order.

One stage can be added to multiple input sources.

The command line option stage is always the first stage of any
input source.
--]
[#assign inputSources = {} ]

[#macro addInputSource id description]
    [#assign inputSources =
        mergeObjects(
            inputSources,
            {
                id : {
                    "Description" : description,
                    "Stages" : [
                        {
                            "Id" : COMMANDLINEOPTIONS_SHARED_INPUT_STAGE,
                            "Priority" : 0
                        }
                    ]
                }
            }
        )
    ]
[/#macro]

[#assign inputStages = {} ]

[#macro addInputStage id description]
    [#assign inputStages =
        mergeObjects(
            inputStages,
            {
                id : {
                    "Description" : description
                }
            }
        )
    ]
[/#macro]

[#assign DEFAULT_INPUT_PRIORITY_INCREMENT = 100]
[#macro addStageToInputSource inputSource inputStage priority="" ]
    [#if inputSources[inputSource]?? && inputStages[inputStage]??]

        [#local lastStage = inputSources[inputSource].Stages?sort_by("Priority")?last ]

        [#assign inputSources =
            combineEntities(
                inputSources,
                {
                    inputSource : {
                        "Stages" : [
                            {
                                "Id" : inputStage,
                                "Priority" :
                                    valueIfTrue(
                                        priority,
                                        priority?is_number,
                                        lastStage.Priority + DEFAULT_INPUT_PRIORITY_INCREMENT
                                    )
                            }
                        ]
                    }
                },
                APPEND_COMBINE_BEHAVIOUR
            )]
    [/#if]
[/#macro]

[#-- Assign implicit stage priorities --]
[#macro addStagesToInputSource inputSource inputStages=[] ]
    [#list asArray(inputStages) as inputStage ]
        [@addStageToInputSource
            inputSource=inputSource
            inputStage= inputStage
        /]
    [/#list]
[/#macro]

[#--
Input seeders provide content to stages. Like stages in an input source,
seeders within an input stage are dynamically ordered so additional
seeders can be dynamically added to an existing input stage.
--]
[#assign inputSeeders = {} ]

[#macro addInputSeeder id description]

    [#assign inputSeeders =
        mergeObjects(
            inputSeeders,
            {
                id : {
                    "Description" : description
                }
            }
        )
    ]
[/#macro]

[#--
Seeders can control whether they apply to any input source or specific input sources, and
their order relative to other seeders.

In general a seeder should not control the priority so that provider loading order
controls the ordering of the seeders but the flexibility is there should a use case emerge.
--]

[#macro addSeederToInputStage inputStage inputSeeder priority="" inputSources="*" ]
    [#if inputSeeders[inputSeeder]??]
        [#local lastSeeder = (inputStages[inputStage].Seeders?sort_by("Priority")?last)!{"Priority" : 0} ]
        [#assign inputStages =
            combineEntities(
                inputStages,
                {
                    inputStage : {
                        "Seeders" : [
                            {
                                "Id" : inputSeeder,
                                "Priority" :
                                    valueIfTrue(
                                        priority,
                                        priority?is_number,
                                        lastSeeder.Priority + DEFAULT_INPUT_PRIORITY_INCREMENT
                                    ),
                                "Sources" : asArray(inputSources)
                            }
                        ]
                    }
                },
                APPEND_COMBINE_BEHAVIOUR
            )
        ]

        [#-- Refresh input state if affected by new seeder --]
        [#local stages = internalGetInputStages(getCurrentInputSource()) ]
        [#list stages?filter(s -> s.Id == inputStage) as stage ]
            [#-- Force cache state to (potentially) new value --]
            [#local cacheHit = refreshInputState(false) ]
        [/#list]
    [/#if]
[/#macro]

[#--
Input filters should only use known attributes. Support the registration of
attributes e.g. by layers or other processing. Distinguish between attributes
to be used internally (engine) and those that can be used in Qualifier filters
(user)
--]
[#--
Engine input filter attributes are used internally but shouldn't be used by users
--]
[#assign engineInputFilterAttributes =
    {
        "InputSource" : {
            "Description" : "Input source being processed"
        },
        "Provider" : {
            "Description" : "Deployment provider"
        },
        "DeploymentUnit" : {
            "Description" : "Deployment unit"
        }
    }
]
[#macro addEngineFilterAttribute id description]
    [#assign engineInputFilterAttributes =
        mergeObjects(
            engineInputFilterAttributes,
            {
                id : {
                    "Description" : description
                }
            }
        )
    ]
[/#macro]

[#--
User input filter attributes are intended to be usable in CMDBs/mock data etc
The main source of these should be layers
--]
[#-- TODO(mfl) remove this set and wire into layer processing --]
[#assign userInputFilterAttributes =
    {
        "Tenant" : {
            "Description" : "tenant layer"
        },
        "Product" : {
            "Description" : "product layer"
        },
        "Environment" : {
            "Description" : "environment layer"
        },
        "Segment" : {
            "Description" : "segment layer"
        },
        "Account" : {
            "Description" : "account layer"
        },
        "Region" : {
            "Description" : "Deployment Region"
        }
    }
]
[#macro addUserFilterAttribute id description]
    [#assign userInputFilterAttributes =
        mergeObjects(
            userInputFilterAttributes,
            {
                id : {
                    "Description" : description
                }
            }
        )
    ]
[/#macro]

[#function getKnownUserInputFilterAttributes]
    [#return userInputFilterAttributes?keys?sort]
[/#function]

[#-- Manage input state --]

[#--
Get the current state of various categories of input
--]
[#function getCommandLineOptions ]
    [#return getInputState().CommandLineOptions!{} ]
[/#function]

[#function getBlueprint ]
    [#return getInputState().Blueprint!{} ]
[/#function]

[#function getSettings ]
    [#return getInputState().Settings!{} ]
[/#function]

[#function getDefinitions ]
    [#return getInputState().Definitions!{} ]
[/#function]

[#--
TODO(mfl) handle getting outputs specially to support simulation stage
We will need to run input processing before attempting to use the
stack outputs to resolve the request
--]
[#function getStackOutputs ]
    [#return getInputState().StackOutputs![] ]
[/#function]

[#--
A stack is used to capture the history of input state changes
--]
[#function getInputState]
    [#return
        isStackEmpty(inputStateStack)?then(
            {},
            inputState
        )
    ]
[/#function]

[#function getCurrentInputSource]
    [#return
        isStackEmpty(inputStateStack)?then(
            "",
            getTopOfStack(inputStateStack).Source
        )
    ]
[/#function]

[#function getCurrentInputFilter]
    [#return
        removeObjectAttributes(
            isStackEmpty(inputStateStack)?then({}, getTopOfStack(inputStateStack).Filter),
            "InputSource"
        )
    ]
[/#function]

[#-- Refresh current state on basis of input state stack --]
[#-- Return whether the cache satisfied the refresh      --]
[#function refreshInputState checkCache=true]
    [#-- Assume cache miss --]
    [#local cacheHit = false]

    [#if isStackNotEmpty(inputStateStack)]
        [#-- Refresh on the basis of the stack state --]
        [#local topOfStack = getTopOfStack(inputStateStack) ]

        [#-- Avoid double searching - once here and once when adding to the cache --]
        [#local knownMiss = false]

        [#if checkCache]
            [#local cacheIndex = internalGetInputStateCacheIndex(topOfStack.Filter) ]
            [#if cacheIndex != INPUT_STATE_CACHE_MISS_INDEX]
                [#assign inputState = internalGetInputStateCacheEntry(cacheIndex) ]
                [#local cacheHit = true]
            [#else]
                [#local knownMiss = true]
            [/#if]
        [/#if]

        [#if !cacheHit]
            [#-- refresh not yet satisfied --]
            [#assign inputState =
                internalAddToInputStateCache(
                    topOfStack.Filter,
                    internalGetInputState(topOfStack.Source, topOfStack.Filter),
                    knownMiss
                )
            ]
        [/#if]
    [/#if]

    [#-- TODO(mfl) remove once migration to new input source structure complete --]
    [#-- refresh commandLineOptions on input state change --]
    [@addCommandLineOption getCommandLineOptions() /]

    [#return cacheHit]
[/#function]

[#macro pushInputSource inputSource inputFilter={} ]

    [#-- Always include the InputSource in the filter --]
    [#local newFilter = inputFilter + {"InputSource" : inputSource} ]

    [#-- Update the stack --]
    [#assign inputStateStack =
        pushOnStack(
            inputStateStack,
            {
                "Source" : inputSource,
                "Filter" : newFilter
            }
        )
    ]

    [#-- Determine the new state leveraging the cache --]
    [#local cacheHit = refreshInputState(true) ]

    [#local historyEntry =
        {
            "Action" : "push",
            "Filter" : newFilter,
            "FromCache" : cacheHit
        }
    ]

    [#assign inputStateStackHistory += [historyEntry] ]

    [@debug
        message="Pushing input state"
        context=historyEntry + {"State" : inputState}
        enabled=false
    /]

[/#macro]

[#--
Filter pushes are additive permitting changes without knowledge of previous state changes,
which is useful in situations like link processing.
--]
[#macro pushInputFilter inputFilter ]
    [#if isStackEmpty(inputStateStack) ]
        [@fatal
            message="Attempt to push incremental state when the state stack is empty"
        /]
    [#else]
        [#local topOfStack = getTopOfStack(inputStateStack) ]
        [@pushInputSource
            topOfStack.Source,
            mergeObjects(
                topOfStack.Filter,
                inputFilter
            )
        /]
    [/#if]
[/#macro]

[#macro popInputState]
    [#assign inputStateStack = popOffStack(inputStateStack) ]

    [#-- Determine the new state leveraging the cache --]
    [#local cacheHit = refreshInputState(true) ]

    [#local historyEntry =
        {
            "Action" : "pop",
            "FromCache" : cacheHit
        }
    ]
    [#assign inputStateStackHistory += [historyEntry] ]

    [@debug
        message="Popping input state"
        context=historyEntry
        enabled=false
    /]

[/#macro]

[#---------------------------------------------------
-- Internal support functions for input processing --
-----------------------------------------------------]

[#--
Get the stages in order for an input source
--]
[#function internalGetInputStages inputSource]
    [#return
        ((inputSources[inputSource].Stages)![])?sort_by("Priority")
    ]
[/#function]

[#--
Get the seeders in order for an input stage
--]
[#function internalGetInputSeeders inputStage]
    [#return
        ((inputStages[inputStage].Seeders)![])?sort_by("Priority")
    ]
[/#function]

[#--
Get the state for the current input filter
--]
[#function internalGetInputState inputSource inputFilter ]
    [#local state = {} ]

    [#-- Get the ordered list of stages to invoke --]
    [#list internalGetInputStages(inputSource) as inputStage]
        [#-- Get the ordered list of seeders to invoke --]
        [#list internalGetInputSeeders(inputStage.Id) as inputSeeder]
            [#-- Ensure seeder is registered for the input source --]
            [#if inputSeeder.Sources?seq_contains(inputSource) || inputSeeder.Sources?seq_contains("*")]

                [#-- Support various level of seeder specificity --]
                [#local seederFunctionOptions =
                    [
                        [ inputSeeder.Id, "inputseeder", inputStage.Id, inputSource ],
                        [ inputSeeder.Id, "inputseeder", inputStage.Id ],
                        [ inputSeeder.Id, "inputseeder" ]
                    ]
                ]

                [#local seederFunction = getFirstDefinedDirective(seederFunctionOptions)]

                [#if (.vars[seederFunction]!"")?is_directive]
                    [#local state = (.vars[seederFunction])(inputFilter, state) ]
                [#else]
                    [@debug
                        message="Unable to invoke any of the input seeder function options"
                        context=seederFunctionOptions
                        enabled=false
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#list]

    [#return state]
[/#function]

[#-- Manage an input state cache --]

[#--
The linear search used is simple but should be adequate in most cases
as processing is typically centred around the initially provided filter values
--]
[#assign INPUT_STATE_CACHE_MISS_INDEX = -1 ]
[#function internalGetInputStateCacheIndex inputFilter]
    [#list inputStateCache as entry]
        [#if filterMatch(inputFilter, entry.Filter, EXACTLY_ONETOONE_FILTER_MATCH_BEHAVIOUR) ]
            [#-- Hit --]
            [#return entry?index]
        [/#if]
    [/#list]

    [#-- Miss --]
    [#return INPUT_STATE_CACHE_MISS_INDEX ]
[/#function]

[#function internalGetInputStateCacheEntry index]
    [#return inputStateCache[index] ]
[/#function]

[#function internalAddToInputStateCache inputFilter inputState knownMiss=false]
    [#if knownMiss ]
        [#-- Always put at the end --]
        [#assign inputStateCache +=
            [
                {
                    "Filter" : inputFilter,
                    "State" : inputState
                }
            ]
        ]
    [#else]
        [#local existingIndex = internalGetInputStateCacheIndex(inputFilter)]
        [#if existingIndex == INPUT_STATE_CACHE_MISS_INDEX]
            [#-- Add to the end --]
            [#assign inputStateCache +=
                [
                    {
                        "Filter" : inputFilter,
                        "State" : inputState
                    }
                ]
            ]
        [#else]
            [#-- Rewrite the cache with the new state --]
            [#local newStateCache = [] ]
            [#list inputStateCache as entry]
                [#if entry?index == existingIndex]
                    [#local newStateCache +=
                        [
                            {
                                "Filter" : inputFilter,
                                "State" : inputState
                            }
                        ]
                    ]
                [#else]
                    [#local newStateCache += [entry] ]
                [/#if]
            [/#list]
            [#assign inputStateCache = newStateCache]
        [/#if]
    [/#if]
    [#return inputState]
[/#function]

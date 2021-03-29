[#ftl]

[#-----------------------------------------
-- Public functions for input processing --
-------------------------------------------]

[#-- History not affected by reinitialisation of input system --]
[#assign inputStateStackHistory = [] ]

[#-- initialise input processing - must be called first --]
[#macro initialiseInputProcessing inputSource inputFilter ]

    [#-- Current input state --]
    [#assign inputState = {} ]

    [#-- Stack of input state changes --]
    [#assign inputStateStack = initialiseStack() ]

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

[#macro registerInputSource id description]
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

[#macro registerInputStage id description]
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

Input seeders contribute to one or more pipelines within the stage.
These represent distinct chains of processing. Each pipeline can use
a different representation of the state that is passed between seeders
appropriate to the purpose of the pipeline.

--]
[#assign inputSeeders = {} ]

[#macro registerInputSeeder id description ]

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
Input transformers perform the same technical function as input seeders
but are distinguished by being driven by user based configuration. If
the function of the transform is fixed, then it should be implemented
as a seeder.
--]
[#assign inputTransformers = {} ]

[#macro registerInputTransformer id description]

    [#assign inputTransformers =
        mergeObjects(
            inputTransformers,
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

A separate call is needed to add a seeder to each pipeline

The pipelines offered are
config - the various types of config provided by the CMDB
state - a single output in the CMDB state
--]

[#assign CONFIG_SEEDER_PIPELINE_TYPE = "Config"]
[#assign STATE_SEEDER_PIPELINE_TYPE = "State"]

[#macro addStepToInputStage stage step function pipeline priority="" sources="*" ]
    [#local lastStep = (inputStages[stage][pipeline]?sort_by("Priority")?last)!{"Priority" : 0} ]
    [#assign inputStages =
        combineEntities(
            inputStages,
            {
                stage : {
                    pipeline : [
                        {
                            "Id" : step,
                            "Priority" :
                                valueIfTrue(
                                    priority,
                                    priority?is_number,
                                    lastStep.Priority + DEFAULT_INPUT_PRIORITY_INCREMENT
                                ),
                            "Sources" : asArray(sources),
                            "Function" : function
                        }
                    ]
                }
            },
            APPEND_COMBINE_BEHAVIOUR
        )
    ]

    [#-- Schedule refresh of input state if affected by new step --]
    [#local stages = internalGetInputStages(getInputSource()) ]
    [#list stages?filter(s -> s.Id == stage) as s ]
        [@debug
            message="Triggering state refresh after adding " + step + " seeder to " + stage + " stage"
            enabled=false
        /]

        [@internalScheduleInputStateRefresh /]
    [/#list]
[/#macro]

[#assign CONFIG_SEEDER_PIPELINE_STEP_FUNCTION = "configseeder"]
[#macro addSeederToConfigPipeline stage seeder priority="" sources="*" ]
    [#if inputSeeders[seeder]??]
        [@addStepToInputStage
            stage=stage
            step=seeder
            function=CONFIG_SEEDER_PIPELINE_STEP_FUNCTION
            pipeline=CONFIG_SEEDER_PIPELINE_TYPE
            priority=priority
            sources=sources
        /]
    [#else]
        [@fatal
            message="Attempt to add an unknown seeder to a stage"
            context=seeder
            stop=true
        /]
    [/#if]
[/#macro]

[#assign STATE_SEEDER_PIPELINE_STEP_FUNCTION = "stateseeder"]
[#macro addSeederToStatePipeline stage seeder priority="" sources="*" ]
    [#if inputSeeders[seeder]??]
        [@addStepToInputStage
            stage=stage
            step=seeder
            function=STATE_SEEDER_PIPELINE_STEP_FUNCTION
            pipeline=STATE_SEEDER_PIPELINE_TYPE
            priority=priority
            sources=sources
        /]
    [#else]
        [@fatal
            message="Attempt to add an unknown seeder to a stage"
            context=seeder
            stop=true
        /]
    [/#if]
[/#macro]

[#assign CONFIG_TRANSFORMER_PIPELINE_STEP_FUNCTION = "configtransformer"]
[#macro addTransformerToConfigPipeline stage transformer priority="" sources="*" ]
    [#if inputTransformers[transformer]??]
        [@addStepToInputStage
            stage=stage
            step=transformer
            function=CONFIG_TRANSFORMER_PIPELINE_STEP_FUNCTION
            pipeline=CONFIG_SEEDER_PIPELINE_TYPE
            priority=priority
            sources=sources
        /]
    [#else]
        [@fatal
            message="Attempt to add an unknown transformer to a stage"
            context=transformer
            stop=true
        /]
    [/#if]
[/#macro]

[#assign STATE_TRANSFORMER_PIPELINE_STEP_FUNCTION = "statetransformer"]
[#macro addTransformerToStatePipeline stage transformer priority="" sources="*" ]
    [#if inputTransformers[transformer]??]
        [@addStepToInputStage
            stage=stage
            step=transformer
            function=STATE_TRANSFORMER_PIPELINE_STEP_FUNCTION
            pipeline=STATE_SEEDER_PIPELINE_TYPE
            priority=priority
            sources=sources
        /]
    [#else]
        [@fatal
            message="Attempt to add an unknown transformer to a stage"
            context=transformer
            stop=true
        /]
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
[#macro registerEngineFilterAttribute id description]
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
Layer input filter attributes are intended to be usable in seeder providers
to filter the data returned
--]
[#assign layerInputFilterAttributes = {} ]

[#macro registerLayerInputFilterAttribute id description]
    [#assign layerInputFilterAttributes =
        mergeObjects(
            layerInputFilterAttributes,
            {
                id : {
                    "Description" : description
                }
            }
        )
    ]
[/#macro]

[#function getRegisteredLayerInputFilterAttributeIds]
    [#return layerInputFilterAttributes?keys?sort]
[/#function]

[#-- Manage input state --]

[#-- Classes of input config data --]
[#assign COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS = "CommandLineOptions" ]
[#assign BLUEPRINT_CONFIG_INPUT_CLASS = "Blueprint" ]
[#assign SETTINGS_CONFIG_INPUT_CLASS = "Settings" ]
[#assign DEFINITIONS_CONFIG_INPUT_CLASS = "Definitions" ]
[#assign FRAGMENT_CONFIG_INPUT_CLASS = "Fragments" ]
[#assign STATE_CONFIG_INPUT_CLASS = "State" ]

[#-- Cache of stage data for situations where back --]
[#-- referencing is need in subsequent stages      --]
[#assign CONFIG_INPUT_PIPELINE_STAGE_CACHE = "StageData" ]

[#-- Convenience Accessor functions that ensure state is up to date --]
[#function getCommandLineOptions ]
    [#return getInputState()[COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS]!{} ]
[/#function]

[#-- TODO(mfl) Remove once input processing complete --]
[#function getMasterdata ]
    [#return
        getConfigPipelineClassCacheForStage(
            getInputState(),
            BLUEPRINT_CONFIG_INPUT_CLASS,
            MASTERDATA_SHARED_INPUT_STAGE
        )!{} ]
[/#function]

[#function getBlueprint ]
    [#return getInputState()[BLUEPRINT_CONFIG_INPUT_CLASS]!{} ]
[/#function]

[#function getSettings ]
    [#return getInputState()[SETTINGS_CONFIG_INPUT_CLASS]!{} ]
[/#function]

[#function getDefinitions ]
    [#return getInputState()[DEFINITIONS_CONFIG_INPUT_CLASS]!{} ]
[/#function]

[#function getFragments ]
    [#return getInputState()[FRAGMENT_CONFIG_INPUT_CLASS]!{} ]
[/#function]

[#function getState ]
    [#return getInputState()[STATE_CONFIG_INPUT_CLASS]![] ]
[/#function]

[#--
Get the value for a point within the state
--]
[#function getStatePoint id deploymentUnit="" account="" region="" level="" ]
    [#-- Get point on basis of current input state --]
    [#local topOfStack = getTopOfStack(inputStateStack) ]

    [#-- Determine result from the state pipeline --]
    [#return
        internalGetStatePipelineValue(
            topOfStack.Source,
            topOfStack.Filter,
            id,
            deploymentUnit,
            account,
            region,
            level
        )
    ]
[/#function]

[#function getStatePointValue id deploymentUnit="" account="" region="" level="" ]
    [#return getStatePoint(id, deploymentUnit, account, region, level).Value ]
[/#function]
[#--
A stack is used to capture the history of input state changes
--]
[#function getInputState refresh=true]
    [#if refresh]
        [@internalRefreshInputState /]
    [/#if]
    [#return
        isStackEmpty(inputStateStack)?then(
            {},
            inputState
        )
    ]
[/#function]

[#function getInputSource]
    [#return
        isStackEmpty(inputStateStack)?then(
            "",
            getTopOfStack(inputStateStack).Source
        )
    ]
[/#function]

[#function getInputFilter]
    [#return
        removeObjectAttributes(
            isStackEmpty(inputStateStack)?then({}, getTopOfStack(inputStateStack).Filter),
            "InputSource"
        )
    ]
[/#function]

[#assign inputStateRefreshInProgress = false]

[#-- Refresh current state on basis of input state stack --]
[#-- Return whether the cache satisfied the refresh      --]
[#function refreshInputState checkCache=true]

    [#-- Recursion detection - may occur if input state is accessed in seeder routines --]
    [#if inputStateRefreshInProgress]
        [@fatal
            message="Attempt to refresh state while a refresh was in progress. Check for input state access in an input seeder function"
            stop=true
        /]
    [/#if]
    [#assign inputStateRefreshInProgress = true]

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
                    internalGetConfigPipelineValue(topOfStack.Source, topOfStack.Filter),
                    knownMiss
                )
            ]
        [/#if]
    [/#if]

    [#-- TODO(mfl) remove once migration to new input source structure complete --]
    [#-- refresh commandLineOptions on input state change                       --]
    [@addCommandLineOption inputState.CommandLineOptions!{} /]

    [#-- End of critical section --]
    [#assign inputStateRefreshInProgress = false]

    [#return cacheHit]
[/#function]

[#macro pushInputSource inputSource inputFilter={} ]

    [#-- Always include the InputSource in the filter --]
    [#local newFilter = inputFilter + {"InputSource" : inputSource} ]

    [@debug
        message="Pushing input source"
        context=newFilter
        enabled=false
    /]

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
        message="New input source state"
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
    [#local topOfStack = getTopOfStack(inputStateStack) ]

    [@debug
        message="Popping input state, new top of stack"
        context=topOfStack.Filter
        enabled=false

    /]

    [#-- Determine the new state leveraging the cache --]
    [#local cacheHit = refreshInputState(true) ]

    [#local historyEntry =
        {
            "Action" : "pop",
            "Filter" : topOfStack.Filter,
            "FromCache" : cacheHit
        }
    ]
    [#assign inputStateStackHistory += [historyEntry] ]

[/#macro]

[#assign pointSetConfiguration =
    {
        "Properties" : [
            {
                "Type"  : "Description",
                "Value" : "Attributes of deployed resources"
            }
        ],
        "Attributes" : [
            {
                "Names" : ["Account", "Subscription"],
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Region",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Level",
                "Types" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "DeploymentUnit",
                "Types" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "*",
                "Types" : STRING_TYPE
            }
        ]
    }
]

[#function validatePointSet pointSet]
    [#return getCompositeObject(pointSetConfiguration.Attributes, pointSet) ]
[/#function]

[#-- Step support functions --]

[#-- Add data to a class and optionally keep the data for subsequent stages --]
[#function addToConfigPipelineClass state class data stage=""]
    [#return
        mergeObjects(
            state,
            {
                class : data
            } +
            attributeIfContent(
                CONFIG_INPUT_PIPELINE_STAGE_CACHE,
                stage,
                {
                    stage : {
                        class : data
                    }
                }
            )
        )
    ]
[/#function]

[#-- Get specific class data for a stage --]
[#function getConfigPipelineClassCacheForStage state class stage]
    [#return state[CONFIG_INPUT_PIPELINE_STAGE_CACHE][stage][class] ]
[/#function]

[#-- Remove specific class data for a stage --]
[#-- Clean up any resulting empty objects   --]
[#function removeConfigPipelineClassCacheForStage state class stage]
    [#local stageCache =
        removeObjectAttributes(
            (state[CONFIG_INPUT_PIPELINE_STAGE_CACHE][stage])!{},
            class
        )
    ]
    [#if stageCache?has_content]
        [#return
            state +
            {
                CONFIG_INPUT_PIPELINE_STAGE_CACHE :
                    state[CONFIG_INPUT_PIPELINE_STAGE_CACHE] +
                    {
                        stage : stageCache
                    }
            }
        ]
    [/#if]
    [#local cache =
        removeObjectAttributes(
            (state[CONFIG_INPUT_PIPELINE_STAGE_CACHE])!{},
            stage
        )
    ]
    [#if cache?has_content]
        [#return
            state +
            {
                CONFIG_INPUT_PIPELINE_STAGE_CACHE : cache
            }
        ]
    [/#if]

    [#return
        removeObjectAttributes(
            state,
            CONFIG_INPUT_PIPELINE_STAGE_CACHE
        )
    ]
[/#function]

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
Get the steps in order for an input stage
--]
[#function internalGetInputSteps inputStage pipeline]
    [#return
        ((inputStages[inputStage][pipeline])![])?sort_by("Priority")
    ]
[/#function]

[#--
Get the effective value of a pipeline for the current input filter
--]
[#function internalGetInputPipelineValue inputSource inputFilter pipeline initialState ]
    [@debug
        message="Evaluating " + pipeline + " pipeline"
        context=inputFilter
        detail=initialState
        enabled=false

    /]
    [#local state = initialState ]
    [#-- Get the ordered list of stages to invoke --]
    [#list internalGetInputStages(inputSource) as inputStage]
        [#-- Get the ordered list of steps to invoke --]
        [#list internalGetInputSteps(inputStage.Id, pipeline) as inputStep]
            [#-- Ensure step is registered for the input source --]
            [#if inputStep.Sources?seq_contains(inputSource) || inputStep.Sources?seq_contains("*")]

                [#-- Support various level of step specificity --]
                [#local stepFunctionOptions =
                    [
                        [ inputStep.Id, inputStep.Function, inputStage.Id, inputSource ],
                        [ inputStep.Id, inputStep.Function, inputStage.Id ],
                        [ inputStep.Id, inputStep.Function ]
                    ]
                ]

                [#local stepFunction = getFirstDefinedDirective(stepFunctionOptions)]

                [#if (.vars[stepFunction]!"")?is_directive]
                    [@debug
                        message="Invoking step function " + stepFunction
                        enabled=false
                    /]
                    [#local state = (.vars[stepFunction])(inputFilter, state) ]
                [#else]
                    [#-- This means a step has been registered but its corresponding    --]
                    [#-- implementation can't be located - likely an implementation bug --]
                    [@fatal
                        message="Unable to invoke any of the input step function options for " + pipeline + " pipeline - check function naming"
                        context=inputStep
                        detail=stepFunctionOptions
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#list]
    [@debug
        message="Evaluation of " + pipeline + " pipeline complete"
        context=inputFilter
        enabled=false
    /]

    [#return state]
[/#function]

[#--
Get the effective value of the config pipeline for the current input source/filter
--]
[#function internalGetConfigPipelineValue inputSource inputFilter ]
    [#return internalGetInputPipelineValue(inputSource, inputFilter, CONFIG_SEEDER_PIPELINE_TYPE, {} ) ]
[/#function]

[#--
Get the effective value of the state pipeline for the current input source/filter
--]
[#function internalGetStatePipelineValue inputSource inputFilter id deploymentUnit account region level ]
    [#return
        internalGetInputPipelineValue(
            inputSource,
            inputFilter,
            STATE_SEEDER_PIPELINE_TYPE,
            {
                "Id" : id,
                "DeploymentUnit" : deploymentUnit,
                "Account" : account,
                "Region" : region,
                "Level" : level,
                "Value" : ""
            }
        )
    ]
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

[#assign inputStateRefreshRequired = false]

[#macro internalScheduleInputStateRefresh ]
    [#assign inputStateRefreshRequired = true]

[/#macro]

[#macro internalRefreshInputState]
    [#if inputStateRefreshRequired]
        [#-- Force cache state to (potentially) new value --]
        [#local cacheHit = refreshInputState(false) ]

        [#-- We want to detect any attempt to access the input state    --]
        [#-- from a seeder/transformer during refresh, so reset the     --]
        [#-- refresh required flag AFTER performing the refresh         --]
        [#-- Seeders should rely on the state provided as an parameter  --]
        [#assign inputStateRefreshRequired = false]
    [/#if]
[/#macro]


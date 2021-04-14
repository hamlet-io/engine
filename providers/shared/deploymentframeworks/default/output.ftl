[#ftl]

[#--------------------------------------------------
-- Public functions for default output processing --
----------------------------------------------------]

[#-- Default script formats --]
[#assign BASH_DEFAULT_OUTPUT_FORMAT = "bash"]
[#assign PS_DEFAULT_OUTPUT_FORMAT = "ps"]

[#-- Default output types --]
[#assign SCRIPT_DEFAULT_OUTPUT_TYPE = "script"]
[#assign JSON_DEFAULT_OUTPUT_TYPE = "json"]
[#assign MODEL_DEFAULT_OUTPUT_TYPE = "model"]
[#assign SCHEMA_DEFAULT_OUTPUT_TYPE = "schema"]
[#assign CONTRACT_DEFAULT_OUTPUT_TYPE = "contract"]
[#assign INFO_DEFAULT_OUTPUT_TYPE = "info" ]
[#assign STATE_OUTPUT_TYPE = "state" ]

[#-- SCRIPT_DEFAULT_OUTPUT_TYPE --]

[#-- A script is considered to consist of a number of ordered sections      --]
[#-- Sections are serialised in alphabetical order.                         --]
[#-- Section content can either be an array of lines or json content,       --]
[#-- with the decision based on the first content provided for the section. --]

[#function isDefaultBashOutput name]
    [#return getOutputFormat(name) == BASH_DEFAULT_OUTPUT_FORMAT ]
[/#function]

[#function isDefaultPSOutput name]
    [#return getOutputFormat(name) == PS_DEFAULT_OUTPUT_FORMAT ]
[/#function]

[#function isDefaultScriptOutput name]
    [#switch getOutputFormat(name)]
        [#case BASH_DEFAULT_OUTPUT_FORMAT ]
        [#case PS_DEFAULT_OUTPUT_FORMAT ]
            [#return true]
        [#default]
            [#return false]
    [/#switch]
[/#function]

[#macro initialiseDefaultBashOutput name ]
    [@initialiseTextOutput
        name=name
        format=BASH_DEFAULT_OUTPUT_FORMAT
        headerLines="#!/usr/bin/env bash"
    /]
[/#macro]

[#macro initialiseDefaultPSOutput name ]
    [@initialiseTextOutput
        name=name
        format=PS_DEFAULT_OUTPUT_FORMAT
        headerLines="#!/usr/bin/env pwsh"
    /]
[/#macro]

[#macro initialiseDefaultScriptOutput format ]
    [#switch format]
        [#case BASH_DEFAULT_OUTPUT_FORMAT ]
            [@initialiseDefaultBashOutput name=SCRIPT_DEFAULT_OUTPUT_TYPE /]
            [#break]
        [#case PS_DEFAULT_OUTPUT_FORMAT ]
            [@initialiseDefaultPSOutput name=SCRIPT_DEFAULT_OUTPUT_TYPE /]
            [#break]
    [/#switch]
[/#macro]

[#function default_output_script_bash level include]
    [#return default_output_script_internal(BASH_DEFAULT_OUTPUT_FORMAT, level, include) /]
[/#function]

[#function default_output_script_ps level include]
    [#return default_output_script_internal(PS_DEFAULT_OUTPUT_FORMAT, level, include) /]
[/#function]

[#-- If multiple formats supported, ignore the ones not needed for current format --]
[#macro addToDefaultBashScriptOutput content=[] section="default"]
    [#if isDefaultBashOutput(SCRIPT_DEFAULT_OUTPUT_TYPE)]
        [@addToTextOutput
            name=SCRIPT_DEFAULT_OUTPUT_TYPE
            lines=content
            section=section
         /]
    [/#if]
[/#macro]

[#macro addToDefaultPSScriptOutput content=[] section="default"]
    [#if isDefaultPSOutput(SCRIPT_DEFAULT_OUTPUT_TYPE)]
        [@addToTextOutput
            name=SCRIPT_DEFAULT_OUTPUT_TYPE
            lines=content
            section=section
        /]
    [/#if]
[/#macro]

[#macro addToDefaultScriptOutput content=[] section="default"]
    [@addToTextOutput
        name=SCRIPT_DEFAULT_OUTPUT_TYPE
        lines=content
        section=section
    /]
[/#macro]

[#-- Initialise the possible outputs to make sure they are available to all steps --]
[@initialiseDefaultScriptOutput format=BASH_DEFAULT_OUTPUT_FORMAT /]
[@initialiseJsonOutput name=JSON_DEFAULT_OUTPUT_TYPE /]

[#-- JSON_DEFAULT_OUTPUT_TYPE --]

[#function default_output_json level include]
    [@setOutputProperties
        properties={ "type:file" : { "format" : "json" }}
    /]

    [@initialiseJsonOutput
        name=JSON_DEFAULT_OUTPUT_TYPE
        messagesAttribute="HamletMessages"
    /]

    [#if include?has_content]
        [#if include?contains("[#ftl]") ]
            [#-- treat as interpretable content --]
            [#local inlineInclude = include?interpret]
            [@inlineInclude /]
        [#else]
            [#-- assume a filename --]
            [#include include?ensure_starts_with("/") ]
        [/#if]
    [#else]
        [@processFlows
            level=level
            framework=DEFAULT_DEPLOYMENT_FRAMEWORK
            flows=getCLOFlows()
        /]
    [/#if]

    [#return serialiseOutput(JSON_DEFAULT_OUTPUT_TYPE) ]
[/#function]

[#macro addToDefaultJsonOutput content={} ]
    [@addToJsonOutput name=JSON_DEFAULT_OUTPUT_TYPE content=content /]
[/#macro]

[#macro mergeWithDefaultJsonOutput content={} ]
    [@mergeWithJsonOutput name=JSON_DEFAULT_OUTPUT_TYPE content=content /]
[/#macro]

[#macro addCliToDefaultJsonOutput id command content={} ]
    [@addToDefaultJsonOutput
        content=
            {
                id : {
                    command : content
                }
            }
    /]
[/#macro]

[#-- Info --]
[#function default_output_info level="" include="" ]
    [@setOutputProperties
        properties={ "type:file" : { "format" : "json" }}
    /]

    [@initialiseJsonOutput name="providers" /]
    [@initialiseJsonOutput name="entrances" /]

    [@processFlows
        level=level
        framework=DEFAULT_DEPLOYMENT_FRAMEWORK
        flows=getCLOFlows()
    /]

    [#return
        {
            "Metadata" : {
                "Id" : "hamlet-info",
                "Prepared" : .now?iso_utc,
                "RunId" : getCLORunId(),
                "RequestReference" : getCLORequestReference(),
                "ConfigurationReference" : getCLOConfigurationReference()
            },
            "Providers" : getOutputContent("providers")?values,
            "Entrances" : getOutputContent("entrances")?values
        }
    ]
[/#function]

[#macro infoProvider id details ]
    [@mergeWithJsonOutput
        name="providers"
        content={
            id : details
        }
    /]
[/#macro]

[#macro infoEntrance id details ]
    [@mergeWithJsonOutput
        name="entrances"
        content={
            id :  details
        }
    /]
[/#macro]

[#-- Schema --]
[#function default_output_schema level="" include=""]

    [@setOutputProperties
        properties={ "type:file" : { "format" : "json" }}
    /]

    [@initialiseJsonOutput name="schema" /]

    [@processFlows
        level=level
        framework=DEFAULT_DEPLOYMENT_FRAMEWORK
        flows=getCLOFlows()
    /]

    [#local schemaType = getCLODeploymentUnit()]
    [#return getOutputContent("schema",  schemaType)!{} ]
[/#function]

[#macro addSchemaToDefaultJsonOutput section config schemaId=""]
    [@mergeWithJsonOutput
        name="schema"
        section=section
        content=
            mergeObjects(
                { "$schema" : HamletSchemas.Root },
                formatJsonSchemaBaseType(config + { "Types" : OBJECT_TYPE }, schemaId),
                { "definitions" : config }
            )
    /]
[/#macro]

[#-- Contract --]
[#assign CONTRACT_EXECUTION_MODE_SERIAL = "serial" ]
[#assign CONTRACT_EXECUTION_MODE_PARALLEL = "parallel" ]
[#assign CONTRACT_EXECUTION_MODE_PRIORITY = "priority" ]

[#macro setupContractOutputs ]
    [#if ! getOutputContent("stages")?has_content ]
        [@initialiseJsonOutput name="stages" /]
        [@initialiseJsonOutput name="steps" /]
    [/#if]
[/#macro]

[#function default_output_contract level="" include=""]

    [@setOutputProperties
        properties={ "type:file" : { "format" : "json" }}
    /]

    [@setupContractOutputs /]

    [#-- Resources --]
    [#if include?has_content]
        [#if include?contains("[#ftl]") ]
            [#-- treat as interpretable content --]
            [#local inlineInclude = include?interpret]
            [@inlineInclude /]
        [#else]
            [#-- assume a filename --]
            [#include include?ensure_starts_with("/") ]
        [/#if]
    [#else]
        [@processFlows
            level=level
            framework=DEFAULT_DEPLOYMENT_FRAMEWORK
            flows=getCLOFlows()
        /]
    [/#if]

    [#local outputStages = getOutputContent("stages")]
    [#local outputSteps = getOutputContent("steps")]

    [#local contractStages = []]

    [#if getOutputContent("stages")?has_content ]

        [#list (getOutputContent("stages")?values)?sort_by("Priority") as stage ]

            [#local stageSteps = []]
            [#if outputSteps[stage.Id]?has_content ]
                [#list (outputSteps[stage.Id]?values)?sort_by("Priority") as step ]
                    [#local stageSteps = combineEntities(
                                            stageSteps,
                                            [
                                                {
                                                    "Id" : step.Id,
                                                    "Type" : step.Type,
                                                    "Priority" : step.Priority,
                                                    "Mandatory" : step.Mandatory,
                                                    "Parameters"  : step.Parameters
                                                }
                                            ],
                                            APPEND_COMBINE_BEHAVIOUR
                    )]
                [/#list]


                [#local contractStages = combineEntities(
                                            contractStages,
                                            [
                                                {
                                                    "Id" : stage.Id,
                                                    "ExecutionMode" : stage.ExecutionMode,
                                                    "Mandatory" : stage.Mandatory,
                                                    "Steps" : stageSteps
                                                }
                                            ],
                                            APPEND_COMBINE_BEHAVIOUR
                )]
            [/#if]
        [/#list]

        [#return
            {
                "Metadata" : {
                    "Id" : getOutputContent("contract"),
                    "Prepared" : .now?iso_utc,
                    "RunId" : getCLORunId(),
                    "RequestReference" : getCLORequestReference(),
                    "ConfigurationReference" : getCLOConfigurationReference(),
                    "Providers" : getPluginMetadata()
                },
                "Stages" : contractStages
            }
        ]
    [/#if]
    [#return {}]
[/#function]

[#macro contractStage id executionMode priority=100 mandatory=true ]
    [@mergeWithJsonOutput
        name="stages"
        content={
            id : {
                "Id" : id,
                "Priority" : priority,
                "Mandatory" : mandatory,
                "ExecutionMode" : executionMode
            }
        }
    /]
[/#macro]

[#macro contractStep id stageId taskType parameters priority=100 mandatory=true  ]
    [@mergeWithJsonOutput
        name="steps"
        content={
            stageId : {
                id : {
                    "Id" : id,
                    "Mandatory" : mandatory,
                    "Priority" : priority
                } +
                getTask(taskType, parameters)
            }
        }
    /]
[/#macro]

[#-- GenerationContract --]

[#-- Generation Contracts create a contract document which outlines what documents need to be generated --]
[#macro addDefaultGenerationContract subsets=[] alternatives=["primary"] ]

    [#local subsets = asArray( subsets ) ]

    [#local alternatives = asArray(alternatives) ]

    [#-- create the contract stage for the pregeneration step --]
    [#-- This will include an extra step for running the pregeneration task --]
    [#if subsets?seq_contains("pregeneration") ]
        [#local stageId = "pregeneration" ]
        [@contractStage
            id=stageId
            executionMode=CONTRACT_EXECUTION_MODE_SERIAL
            priority=10
        /]

        [@contractStep
            id=formatId(stageId, "generation")
            stageId=stageId
            taskType=PROCESS_TEMPLATE_PASS_TASK_TYPE
            priority=10
            parameters=
                getGenerationContractStepParameters(
                    "pregeneration",
                    "primary"
                )
        /]

        [#local subsets = removeValueFromArray(subsets, "pregeneration")]
    [/#if]

    [#-- create the contract stages --]
    [#list alternatives as alternative ]
        [#local stageId = formatId("generation", alternative) ]
        [@contractStage
            id=stageId
            executionMode=CONTRACT_EXECUTION_MODE_PARALLEL
        /]

        [#list subsets as subset ]
            [@contractStep
                id=formatId(stageId, subset)
                stageId=stageId
                taskType=PROCESS_TEMPLATE_PASS_TASK_TYPE
                parameters=
                    getGenerationContractStepParameters(
                        subset,
                        alternative
                    )
            /]
        [/#list]
    [/#list]

    [#-- Cleanup stages --]
    [#local cleanUpStageId="cleanup" ]
    [@contractStage
        id=cleanUpStageId
        executionMode=CONTRACT_EXECUTION_MODE_SERIAL
        priority=100
    /]

    [@contractStep
        id=formatId(cleanUpStageId, "generationcontract")
        stageId=cleanUpStageId
        taskType=RENAME_FILE_TASK_TYPE
        parameters={
            "currentFileName" : getCommandLineOptions().Output.FileName,
            "newFileName" : getOutputFileName("generationcontract", "primary")
        }
    /]

[/#macro]

[#-- Occurrence State --]
[#function default_output_state level="" include=""]
    [@setOutputProperties
        properties={ "type:file" : { "format" : "json" }}
    /]
    [@initialiseJsonOutput name="states" /]

    [@processFlows
        level=level
        framework=DEFAULT_DEPLOYMENT_FRAMEWORK
        flows=getCLOFlows()
    /]

    [#local allStates = {}]

    [#if getOutputContent("states")?has_content ]

        [#list getOutputContent("states") as type, states ]

            [#local typedStates = []]

            [#list states?values as state ]

                [#local typedStates = combineEntities(
                                            typedStates,
                                            [
                                                state
                                            ],
                                            APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#local allStates = mergeObjects( allStates, { type : typedStates } )]
        [/#list]

        [#return
            mergeObjects(
                {
                    "Metadata" : {
                        "Id" : "state",
                        "Prepared" : .now?iso_utc,
                        "RunId" : getCLORunId(),
                        "RequestReference" : getCLORequestReference(),
                        "ConfigurationReference" : getCLOConfigurationReference()
                    }
                },
                allStates
            )
        ]
    [/#if]
    [#return {} ]
[/#function]

[#macro stateEntry type id state ]
    [@mergeWithJsonOutput
        name="states"
        content={
            type : {
                id : state
            }
        }
    /]
[/#macro]


[#-- Add Output Step mappings for each output --]
[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="generationcontract"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="generation-contract.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="pregeneration"
    outputType=SCRIPT_DEFAULT_OUTPUT_TYPE
    outputFormat=getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE)
    outputSuffix="pregeneration.sh"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="prologue"
    outputType=SCRIPT_DEFAULT_OUTPUT_TYPE
    outputFormat=getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE)
    outputSuffix="prologue.sh"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="epilogue"
    outputType=SCRIPT_DEFAULT_OUTPUT_TYPE
    outputFormat=getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE)
    outputSuffix="epilogue.sh"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="testcase"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="testcase.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="cli"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="cli.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="config"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="config.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="parameters"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="parameters.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="schema"
    outputType=SCHEMA_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="schema.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="schemacontract"
    outputType=CONTRACT_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="schemacontract.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="managementcontract"
    outputType=CONTRACT_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="managementcontract.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="plugincontract"
    outputType=CONTRACT_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="plugincontract.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="info"
    outputType=INFO_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="info.json"
/]

[@addGenerationContractStepOutputMapping
    provider=SHARED_PROVIDER
    subset="state"
    outputType=STATE_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="state.json"
/]


[#------------------------------------------------------------
-- internal support functions for default output processing --
--------------------------------------------------------------]

[#-- SCRIPT_DEFAULT_OUTPUT_TYPE --]

[#-- Internal use only --]
[#function default_output_script_internal format level include]
    [@setOutputProperties
        properties={ "type:file" : { "format" : "plaintext" }}
    /]

    [#if !isOutput(SCRIPT_DEFAULT_OUTPUT_TYPE) ]
        [@initialiseDefaultScriptOutput format=format /]
    [/#if]

    [#if include?has_content]
        [#if include?contains("[#ftl]") ]
            [#-- treat as interpretable content --]
            [#local inlineInclude = include?interpret]
            [@inlineInclude /]
        [#else]
            [#-- assume a filename --]
            [#include include?ensure_starts_with("/") ]
        [/#if]
    [#else]
          [@processFlows
            level=level
            framework=DEFAULT_DEPLOYMENT_FRAMEWORK
            flows=getCLOFlows()
        /]
    [/#if]

    [#return serialiseOutput(SCRIPT_DEFAULT_OUTPUT_TYPE) /]
[/#function]

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

[#macro default_output_script_bash level include]
    [@default_output_script_internal format=BASH_DEFAULT_OUTPUT_FORMAT level=level include=include /]
[/#macro]

[#macro default_output_script_ps level include]
    [@default_output_script_internal format=PS_DEFAULT_OUTPUT_FORMAT level=level include=include/]
[/#macro]

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

[#-- JSON_DEFAULT_OUTPUT_TYPE --]

[#macro default_output_json level include]
    [@initialiseJsonOutput
        name=JSON_DEFAULT_OUTPUT_TYPE
        messagesAttribute="COTMessages"
    /]

    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processFlows
            level=level
            framework=DEFAULT_DEPLOYMENT_FRAMEWORK
            flows=commandLineOptions.Flow.Names
        /]
    [/#if]

    [@addMessagesToJsonOutput
        name=JSON_DEFAULT_OUTPUT_TYPE
        messages=logMessages
    /]

    [@serialiseOutput name=JSON_DEFAULT_OUTPUT_TYPE /]
[/#macro]

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


[#-- MODEL_DEFAULT_OUTPUT_TYPE --]

[#macro default_output_model level include]
    [@initialiseJsonOutput
        name=MODEL_DEFAULT_OUTPUT_TYPE
        messagesAttribute="COTMessages"
    /]
    [@mergeWithJsonOutput
        name=MODEL_DEFAULT_OUTPUT_TYPE
        content=model
    /]
    [@addMessagesToJsonOutput
        name=MODEL_DEFAULT_OUTPUT_TYPE
        messages=logMessages
    /]
    [@serialiseOutput
        name=MODEL_DEFAULT_OUTPUT_TYPE
    /]
[/#macro]

[#-- Contract --]
[#assign CONTRACT_EXECUTION_MODE_SERIAL = "serial" ]
[#assign CONTRACT_EXECUTION_MODE_PARALLEL = "parallel" ]
[#assign CONTRACT_EXECUTION_MODE_PRIORITY = "priority" ]

[@initialiseJsonOutput name="stages" /]
[@initialiseJsonOutput name="steps" /]

[#macro default_output_contract level="" include=""]
    [#-- Resources --]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processFlows
            level=level
            framework=DEFAULT_DEPLOYMENT_FRAMEWORK
            flows=commandLineOptions.Flow.Names
        /]
    [/#if]

    [#local outputStages = getOutputContent("stages")]
    [#local outputSteps = getOutputContent("steps")]

    [#local contractStages = []]

    [#if getOutputContent("stages")?has_content || logMessages?has_content ]

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

        [@toJSON
            {
                "Metadata" : {
                    "Id" : getOutputContent("contract"),
                    "Prepared" : .now?iso_utc,
                    "RunId" : commandLineOptions.Run.Id,
                    "RequestReference" : commandLineOptions.References.Request,
                    "ConfigurationReference" : commandLineOptions.References.Configuration
                },
                "Stages" : contractStages
            } +
            attributeIfContent("COTMessages", logMessages)
        /]
    [/#if]
    [@serialiseOutput name=JSON_DEFAULT_OUTPUT_TYPE /]
[/#macro]

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
                    "primary",
                    (commandLineOptions.Deployment.Provider.Names)[0]
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
                        alternative,
                        (commandLineOptions.Deployment.Provider.Names)[0]
                    )
            /]
        [/#list]
    [/#list]
[/#macro]

[#-- Initialise the possible outputs to make sure they are available to all steps --]
[@initialiseDefaultScriptOutput format=BASH_DEFAULT_OUTPUT_FORMAT /]
[@initialiseJsonOutput name=JSON_DEFAULT_OUTPUT_TYPE /]

[#-- Add Output Step mappings for each output --]
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
    subset="managementcontract"
    outputType=CONTRACT_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="managementcontract.json"
/]


[#------------------------------------------------------------
-- internal support functions for default output processing --
--------------------------------------------------------------]

[#-- SCRIPT_DEFAULT_OUTPUT_TYPE --]

[#-- Internal use only --]
[#macro default_output_script_internal format level include]
    [#if !isOutput(SCRIPT_DEFAULT_OUTPUT_TYPE) ]
        [@initialiseDefaultScriptOutput format=format /]
    [/#if]

    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
          [@processFlows
            level=level
            framework=DEFAULT_DEPLOYMENT_FRAMEWORK
            flows=commandLineOptions.Flow.Names
        /]
    [/#if]

    [@addMessagesToOutput
        name=SCRIPT_DEFAULT_OUTPUT_TYPE
        messages=logMessages
    /]
    [@serialiseOutput name=SCRIPT_DEFAULT_OUTPUT_TYPE /]
[/#macro]

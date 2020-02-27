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
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processComponents level /]
    [/#if]
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

[#macro addTestPlanToDefaultJsonOutput tests ]
    [@addToDefaultJsonOutput
        content={ "Tests" : tests }
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

[@initialiseJsonOutput name="stages" /]
[@initialiseJsonOutput name="steps" /]

[#macro default_output_contract level="" include=""]
    [#-- Resources --]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processComponents level /]
    [/#if]

    [#local outputStages = getOutputContent("stages")]
    [#local outputSteps = getOutputContent("steps")]

    [#local contractStages = []]

    [#if getOutputContent("stages")?has_content || logMessages?has_content ]
        [#list getOutputContent("stages") as stage ]
            [#local stageSteps = []]
            [#list outputSteps[stage.Id]![] as id,step ]
                [#local stageSteps = combineEntities(
                                        stageSteps,
                                        {
                                            "Id" : id
                                        } + step,
                                        APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]


            [#local contractStages = combineEntities(
                                        contractStages,
                                        [
                                            stage +
                                            {
                                                "Steps" : stageSteps
                                            }
                                        ]
            )]
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

[#macro contractStage id executionMode ]
    [@mergeWithJsonOutput
        name="stages"
        content=[
            {
                "Id" : id,
                "ExecutionMode" : executionMode
            }
        ]
    /]
[/#macro]

[#macro contractStep id stageId taskType parameters ]
    [@mergeWithJsonOutput
        name="steps"
        content={
            stageId : {
                id : getTask(taskType, parameters)
            }
        }
    /]
[/#macro]

[#-- GenerationContract --]

[#-- Genplans leverage the general script output but add JSON based sections --]
[#-- to order steps and ensure steps aren't repeated.                        --]
[#-- Genplan sections have their own converter to convert the JSON to text   --]

[#-- Genplan header - named to come after script header but before genplan content --]
[#assign HEADER_GENPLAN_DEFAULT_OUTPUT_SECTION="100header"]

[#macro addDefaultGenerationPlan subsets=[] alternatives=["primary"] ]

    [#-- create the contract stage for the pregeneration step --]
    [#-- This will include an extra step for running the pregeneration task --]
    [#if subsets?seq_contains("pregeneration") ]
        [#local stageId = "pregeneration" ]
        [@contractStage
            id=stageId
            executionMode=CONTRACT_EXECUTION_MODE_SERIAL
        /]

        [@contractStep
            id=formatId(stageId, "generation")
            stageId=stageId
            task="core_create_template"
            parameters=
                getGenerationContractStepParameters(
                    "pregeneration",
                    "pregeneration",
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
                task="core_create_template"
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

[#function genplan_script_output_converter args=[] ]
    [#local result = [] ]
    [#list args[0] as subset, subsetValue]
        [#list subsetValue as alternative, alternativeValue]
            [#list alternativeValue as provider, providerValue]
                [#list providerValue as deploymentFramework, value]
                    [#local step_name = value.Name]
                    [#local result +=
                        [
                            "## ${step_name} ##",
                            "plan_steps+=(\"${step_name}\")",
                            "plan_subsets[\"${step_name}\"]=\"" + subset + "\"",
                            "plan_alternatives[\"${step_name}\"]=\"" + alternative + "\"",
                            "plan_providers[\"${step_name}\"]=\"" + (commandLineOptions.Deployment.Provider.Names)?join(",") + "\"",
                            "plan_deployment_frameworks[\"${step_name}\"]=\"" + deploymentFramework + "\"",
                            "plan_output_types[\"${step_name}\"]=\"" + value.OutputType + "\"",
                            "plan_output_formats[\"${step_name}\"]=\"" + value.OutputFormat + "\"",
                            "plan_output_suffixes[\"${step_name}\"]=\"" + value.OutputSuffix + "\"",
                            "#"
                        ] ]
                [/#list]
            [/#list]
        [/#list]
    [/#list]
    [#return result]
[/#function]


[#-- Initialise the possible outputs to make sure they are available to all steps --]
[@initialiseDefaultScriptOutput format=BASH_DEFAULT_OUTPUT_FORMAT /]
[@initialiseJsonOutput name=JSON_DEFAULT_OUTPUT_TYPE /]

[#-- Add Output Step mappings for each output --]
[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subset="genplan"
    outputType=SCRIPT_DEFAULT_OUTPUT_TYPE
    outputFormat=getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE)
    outputSuffix="genplan.sh"
/]

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subset="pregeneration"
    outputType=SCRIPT_DEFAULT_OUTPUT_TYPE
    outputFormat=getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE)
    outputSuffix="pregeneration.sh"
/]

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subset="prologue"
    outputType=SCRIPT_DEFAULT_OUTPUT_TYPE
    outputFormat=getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE)
    outputSuffix="prologue.sh"
/]

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subset="epilogue"
    outputType=SCRIPT_DEFAULT_OUTPUT_TYPE
    outputFormat=getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE)
    outputSuffix="epilogue.sh"
/]

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subset="testcase"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="testcase.json"
/]

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subset="cli"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="cli.json"
/]

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subset="config"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="config.json"
/]

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subset="parameters"
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
    outputSuffix="parameters.json"
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
        [@processComponents level /]
    [/#if]

    [@addMessagesToOutput
        name=SCRIPT_DEFAULT_OUTPUT_TYPE
        messages=logMessages
    /]
    [@serialiseOutput
        name=SCRIPT_DEFAULT_OUTPUT_TYPE
    /]
[/#macro]

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

[#-- GENPLAN --]

[#-- Genplans leverage the general script output but add JSON based sections --]
[#-- to order steps and ensure steps aren't repeated.                        --]
[#-- Genplan sections have their own converter to convert the JSON to text   --]

[#-- Genplan header - named to come after script header but before genplan content --]
[#assign HEADER_GENPLAN_DEFAULT_OUTPUT_SECTION="100header"]

[#macro addDefaultGenerationPlan subsets=[] alternatives=["primary"]  section="default" ]

    [#-- First ensure we have captured the gen plan header --]
    [#if !isOutputSection(SCRIPT_DEFAULT_OUTPUT_TYPE, HEADER_GENPLAN_DEFAULT_OUTPUT_SECTION)]
        [@addOutputSection
            name=SCRIPT_DEFAULT_OUTPUT_TYPE
            section=HEADER_GENPLAN_DEFAULT_OUTPUT_SECTION
            initialContent=
                [
                    "local plan_steps=()",
                    "declare -A plan_subsets",
                    "declare -A plan_alternatives",
                    "declare -A plan_providers",
                    "declare -A plan_deployment_frameworks",
                    "declare -A plan_output_types",
                    "declare -A plan_output_formats",
                    "#"
                ]
        /]
    [/#if]


    [#local subsets = combineEntities( subsets, [ "testplan" ], UNIQUE_COMBINE_BEHAVIOUR) ]

    [#list asArray(subsets) as subset]
        [#-- Each subset gets its own section --]
        [#local name = "" ]
        [#switch subset]
            [#case "genplan"]
                [#local name = section + "-100" ]
                [#break]
            [#case "testplan"]
                [#local name = section + "-200"]
                [#break]
            [#case "pregeneration"]
                [#local name = section + "-300"]
                [#break]
            [#case "prologue"]
                [#local name = section + "-400"]
                [#break]
            [#case "template"]
                [#local name = section + "-500"]
                [#break]
            [#case "epilogue"]
                [#local name = section + "-600"]
                [#break]
            [#case "cli"]
                [#local name = section + "-700"]
                [#break]
            [#case "config"]
                [#local name = section + "-800"]
                [#break]
        [/#switch]

        [#-- Unknown subset --]
        [#if !name?has_content]
            [#continue]
        [/#if]

        [#-- Create section if not already defined --]
        [#if !isOutputSection(SCRIPT_DEFAULT_OUTPUT_TYPE, name)]
            [@addOutputSection
                name=SCRIPT_DEFAULT_OUTPUT_TYPE
                section=name
                initialContent={}
                converter="genplan_script_output_converter"
            /]
        [/#if]

        [#-- Now add the steps --]
        [@mergeWithJsonOutput
            name=SCRIPT_DEFAULT_OUTPUT_TYPE
            content=getGenerationPlanSteps(subset, alternatives)
            section=name
        /]
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
                            "plan_providers[\"${step_name}\"]=\"" + provider + "\"",
                            "plan_deployment_frameworks[\"${step_name}\"]=\"" + deploymentFramework + "\"",
                            "plan_output_types[\"${step_name}\"]=\"" + value.OutputType + "\"",
                            "plan_output_formats[\"${step_name}\"]=\"" + value.OutputFormat + "\"",
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

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subsets=[
        "genplan",
        "pregeneration",
        "prologue",
        "epilogue"
    ]
    outputType=SCRIPT_DEFAULT_OUTPUT_TYPE
    outputFormat=getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE)
/]

[@addGenPlanStepOutputMapping
    provider=SHARED_PROVIDER
    subsets=[
        "testplan",
        "cli",
        "config"
    ]
    outputType=JSON_DEFAULT_OUTPUT_TYPE
    outputFormat=""
/]

[#-- TESTPLAN --]
[#macro addDefaultTestPlan ]
    [@addToDefaultJsonOutput content=testPlan /]
[/#macro]

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

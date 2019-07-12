[#ftl]

[#-- Default script formats --]
[#assign DEFAULT_OUTPUT_BASH_FORMAT = "bash"]
[#assign DEFAULT_OUTPUT_PS_FORMAT = "ps"]

[#-- Default output types --]
[#assign DEFAULT_OUTPUT_SCRIPT_TYPE = "script"]
[#assign DEFAULT_OUTPUT_JSON_TYPE = "json"]
[#assign DEFAULT_OUTPUT_MODEL_TYPE = "model"]

[#-- Script output --]

[#function isDefaultBashOutput name]
    [#return outputs[name].Format == DEFAULT_OUTPUT_BASH_FORMAT ]
[/#function]

[#function isDefaultPSOutput name]
    [#return outputs[name].Format == DEFAULT_OUTPUT_PS_FORMAT ]
[/#function]

[#function isDefaultScriptOutput name]
    [#switch outputs[name].Format]
        [#case DEFAULT_OUTPUT_BASH_FORMAT ]
        [#case DEFAULT_OUTPUT_PS_FORMAT ]
            [#return true]
        [#default]
            [#return false]
    [/#switch]
[/#function]

[#macro initialiseDefaultBashOutput name ]
    [@initialiseTextOutput
        name=name
        format=DEFAULT_OUTPUT_BASH_FORMAT
        headerLines="#!/usr/bin/env bash"
    /]
[/#macro]

[#macro initialiseDefaultPSOutput name ]
    [@initialiseTextOutput
        name=name
        format=DEFAULT_OUTPUT_PS_FORMAT
        headerLines="#!/usr/bin/env pwsh"
    /]
[/#macro]

[#macro initialiseDefaultScriptOutput format ]
    [#switch format]
        [#case DEFAULT_OUTPUT_BASH_FORMAT ]
            [@initialiseDefaultBashOutput name=DEFAULT_OUTPUT_SCRIPT_TYPE /]
            [#break]
        [#case DEFAULT_OUTPUT_PS_FORMAT ]
            [@initialiseDefaultPSOutput name=DEFAULT_OUTPUT_SCRIPT_TYPE /]
            [#break]
    [/#switch]
[/#macro]

[#-- Output macros for default deployment framework --]

[#-- DEFAULT_OUTPUT_SCRIPT_TYPE --]

[#-- Internal use only --]
[#macro default_output_script_internal format level include]
    [#if !isOutput(DEFAULT_OUTPUT_SCRIPT_TYPE) ]
        [@initialiseDefaultScriptOutput format=format /]
    [/#if]

    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processComponents level /]
    [/#if]

    [@addMessagesToOutput name=DEFAULT_OUTPUT_SCRIPT_TYPE messages=logMessages /]
    [@serialiseOutput DEFAULT_OUTPUT_SCRIPT_TYPE /]
[/#macro]

[#macro default_output_script_bash level include]
    [@default_output_script_internal format=DEFAULT_OUTPUT_BASH_FORMAT level=level include=include /]
[/#macro]

[#macro default_output_script_ps level include]
    [@default_output_script_internal format=DEFAULT_OUTPUT_PS_FORMAT level=level include=include/]
[/#macro]

[#-- If multiple formats supported, ignore the ones not needed for current format --]
[#macro addToDefaultBashScriptOutput content=[] ]
    [#if isDefaultBashOutput(DEFAULT_OUTPUT_SCRIPT_TYPE)]
        [@addToTextOutput name=DEFAULT_OUTPUT_SCRIPT_TYPE lines=content /]
    [/#if]
[/#macro]

[#macro addToDefaultPSScriptOutput content=[] ]
    [#if isDefaultPSOutput(DEFAULT_OUTPUT_SCRIPT_TYPE)]
        [@addToTextOutput name=DEFAULT_OUTPUT_SCRIPT_TYPE lines=content /]
    [/#if]
[/#macro]

[#macro addToDefaultScriptOutput content=[] ]
    [@addToTextOutput name=DEFAULT_OUTPUT_SCRIPT_TYPE lines=content /]
[/#macro]

[#-- DEFAULT_OUTPUT_JSON_TYPE --]

[#macro default_output_json level include]
    [@initialiseJsonOutput name=DEFAULT_OUTPUT_JSON_TYPE /]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processComponents level /]
    [/#if]
    [@serialiseOutput name=DEFAULT_OUTPUT_JSON_TYPE /]
[/#macro]

[#macro addToDefaultJsonOutput content={} ]
    [@addToJsonOutput name=DEFAULT_OUTPUT_JSON_TYPE content=content /]
[/#macro]

[#macro mergeWithDefaultJsonOutput content={} ]
    [@mergeWithJsonOutput name=DEFAULT_OUTPUT_JSON_TYPE content=content /]
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

[#-- DEFAULT_OUTPUT_MODEL_TYPE --]
[#macro default_output_model level include]
    [@initialiseJsonOutput name=DEFAULT_OUTPUT_JSON_TYPE /]
    [@addToDefaultJsonOutput content=rootContext /]
    [@serialiseOutput name=DEFAULT_OUTPUT_JSON_TYPE /]
[/#macro]

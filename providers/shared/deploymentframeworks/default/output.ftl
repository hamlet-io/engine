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

    [#local outputFormat = "json"]
    [#if getCLODeploymentOutputConversion() == "yaml"]
        [#local outputFormat = "yaml"]
    [/#if]

    [@setOutputProperties
        properties={ "type:file" : { "format" : outputFormat }}
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
    [@initialiseJsonOutput name="referencetypes" /]
    [@initialiseJsonOutput name="referencedata" /]
    [@initialiseJsonOutput name="layertypes" /]
    [@initialiseJsonOutput name="layerdata" /]

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
            "Entrances" : getOutputContent("entrances")?values,
            "ReferenceTypes" : getOutputContent("referencetypes")?values,
            "ReferenceData" : asFlattenedArray(getOutputContent("referencedata")?values),
            "LayerTypes" : getOutputContent("layertypes")?values,
            "LayerData" : getOutputContent("layerdata")?values,
            "ComponentTypes" : getOutputContent("componenttypes")?values
        }
    ]
[/#function]

[#macro infoContent type id details ]
    [@mergeWithJsonOutput
        name=type
        content={
            id : details
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
        [@initialiseJsonOutput name="properties" /]
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
    [#local outputProperties = getOutputContent("properties")]

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
                                                    "Status" : step.Status,
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
                "Properties" : outputProperties,
                "Stages" : contractStages
            }
        ]
    [/#if]
    [#return {}]
[/#function]

[#macro contractProperties properties ]
    [@mergeWithJsonOutput
        name="properties"
        content=properties
    /]
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

[#macro contractStep id stageId taskType parameters priority=100 mandatory=true status="available"  ]
    [@mergeWithJsonOutput
        name="steps"
        content={
            stageId : {
                id : formatContractStep(id, taskType, parameters, priority, mandatory, status )
            }
        }
    /]
[/#macro]

[#function formatContractStep id taskType parameters priority=100 mandatory=true status="available" ]

    [#local supportedStatuses = [ "available", "completed", "failed" ]]
    [#if ! (supportedStatuses?seq_contains(status)) ]
        [@fatal
            message="Invalid contract step status"
            detail={
                "ProvidedStatus" : status,
                "SupportedStatuses" : supportedStatus
            }
        /]
    [/#if]

    [#return
        {
            "Id" : id,
            "Mandatory" : mandatory,
            "Priority" : priority,
            "Status" : status
        } +
        getTask(taskType, parameters)
    ]
[/#function]

[#-- GenerationContract --]

[#-- Generation Contracts create a contract document which outlines what documents need to be generated --]
[#macro addDefaultGenerationContract subsets=[] alternatives=["primary"] converters=[] templateSubset="" ]

    [#local subsets = asArray( subsets ) ]
    [#local alternatives = asArray(alternatives) ]
    [#local converters = asArray(converters) ]

    [#local pregeneration = false ]

    [@contractProperties
        properties=getGenerationContractProperties()
    /]

    [#-- create the contract stage for the pregeneration step --]
    [#-- This will include an extra step for running the pregeneration task --]
    [#if subsets?seq_contains("pregeneration") ]

        [#local pregeneration = true ]

        [#local stageId = "pregeneration" ]
        [@contractStage
            id=stageId
            executionMode=CONTRACT_EXECUTION_MODE_SERIAL
            priority=10
        /]

        [#local pregenerationPassId = formatId(stageId, "pregeneration")]
        [#local pregenerationPassParameters = getGenerationContractStepParameters(
                                                    "pregeneration",
                                                    "",
                                                    ""
                                                )]
        [@contractStep
            id=pregenerationPassId
            stageId=stageId
            taskType=PROCESS_TEMPLATE_PASS_TASK_TYPE
            priority=10
            parameters=pregenerationPassParameters
            status="completed"

        /]

        [@addEntrancePass
            contractStep=
                formatContractStep(
                    pregenerationPassId,
                    PROCESS_TEMPLATE_PASS_TASK_TYPE
                    pregenerationPassParameters,
                    10,
                    true,
                    "completed"
                )
        /]

        [@contractStep
            id=formatId(stageId, "pregeneration", "run")
            stageId=stageId
            taskType=RUN_BASH_SCRIPT_TASK_TYPE
            priority=20
            parameters={
                "scriptFileName" : getOutputFileName("pregeneration", "", "")
            }
        /]

        [#local subsets = removeValueFromArray(subsets, "pregeneration")]
    [/#if]

    [#local subsetAlternatives = [] ]
    [#list alternatives as alternative ]
        [#if alternative?is_string ]
            [#list subsets as subset ]
                [#local subsetAlternatives += [{ "subset" : subset, "alternative" : alternative}] ]
            [/#list]
        [/#if]

        [#if alternative?is_hash ]
            [#if subsets?seq_contains(alternative.subset)]
                [#local subsetAlternatives += [{ "subset" : alternative.subset, "alternative" : alternative.alternative}] ]
            [/#if]
        [/#if]
    [/#list]

    [#-- create the contract stages --]
    [#local subsetStageId = formatId("generation", "subsets") ]
    [#if subsetAlternatives?has_content ]
        [@contractStage
            id=subsetStageId
            executionMode=CONTRACT_EXECUTION_MODE_PARALLEL
        /]
    [/#if]

    [#list subsetAlternatives as subsetAlternative ]
        [#local subset = subsetAlternative.subset]
        [#local alternative = subsetAlternative.alternative ]

        [#local converter = ""]
        [#if converters?has_content && converters?is_sequence ]
            [#list converters as subsetConverter ]
                [#if subset == subsetConverter.subset ]
                    [#local converter = subsetConverter.converter]
                [/#if]
            [/#list]
        [/#if]

        [#local stepId = formatId(subsetStageId, alternative, subset)]
        [#local stepParameters =
                    getGenerationContractStepParameters(
                        subset,
                        alternative,
                        converter,
                        templateSubset
                    )]

        [@contractStep
            id=stepId
            stageId=subsetStageId
            taskType=PROCESS_TEMPLATE_PASS_TASK_TYPE
            parameters=stepParameters
            status=(pregeneration)?then(
                        "available",
                        "completed"
                    )

        /]

        [#-- If pregeneration is not required we can complete this pass as part of this entrance invoke --]
        [#if ! pregeneration ]
            [@addEntrancePass
                contractStep=
                    formatContractStep(
                        stepId,
                        PROCESS_TEMPLATE_PASS_TASK_TYPE
                        stepParameters,
                        100,
                        true,
                        "completed"
                    )
            /]
        [/#if]
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
            "newFileName" : getOutputFileName("generationcontract", "primary", "")
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

[@addGenerationContractStepOutputMappingConverter
    provider=SHARED_PROVIDER
    subset="config"
    id="config_yaml"
    outputSuffix="config.yaml"
    outputConversion="yaml"
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

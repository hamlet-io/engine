[#ftl]

[#------------------------------------------
-- Public functions for output generation --
--------------------------------------------]

[#assign OUTPUT_TEXT_FORMAT = "text"]
[#assign OUTPUT_JSON_FORMAT = "json"]

[#-- Support multiple output streams simultaneously           --]
[#-- Useful if assembling in parts e.g. resources and outputs --]
[#assign outputs = {} ]

[#macro clearOutputs ]
    [#assign outputs = {}]
[/#macro]

[#-- An output has one or more named sections to which content is added.   --]
[#-- The serialiser macro converts the content of each section into a      --]
[#-- format suitable for the format of the output.                         --]
[#-- Attributes provide metadata about the output specific to each format. --]
[#macro createOutput name format attributes={} serialiser="" ]
    [#assign outputs +=
        {
            name :
                {
                    "Sections" : {},
                    "ContentAdded" : false,
                    "Attributes" : attributes,
                    "Format" : format,
                    "Serialiser" : serialiser
                }
        } ]
[/#macro]

[#-- The content first added to a section defines the section content type --]
[#-- The converter is an optional function to convert the section content  --]
[#-- to be compatible with the output format                               --]
[#macro addOutputSection name section initialContent converter=""]
    [#assign outputs =
        combineEntities(
            outputs,
            {
                name : {
                    "Sections" : {
                        section : {
                            "Content" : initialContent
                        } +
                        attributeIfContent("Converter", converter)
                    }
                }
            }
        ) ]
[/#macro]

[#macro addOutputContent name content section="default" treatAsContent=true behaviour=ADD_COMBINE_BEHAVIOUR]
    [#if content?has_content]
        [#local newContent = content]
        [#if isOutputSection(name, section)]
            [#local newContent =
                combineEntities(
                    outputs[name].Sections[section].Content,
                    content,
                    behaviour)]
        [/#if]
        [#assign outputs =
            combineEntities(
                outputs,
                {
                    name : {
                        "Sections" : {
                            section : {
                                "Content" : newContent
                            }
                        }
                    } +
                    attributeIfTrue("ContentAdded", treatAsContent, true)
                }
            ) ]
    [/#if]
[/#macro]

[#macro addOutputAttributes name attributes={} ]
    [#if attributes?has_content]
        [#assign outputs =
            mergeObjects(
                outputs,
                {
                    name : {
                        "Attributes" : attributes
                    }
                }
            ) ]
    [/#if]
[/#macro]

[#function isOutput name]
    [#return outputs[name]?? ]
[/#function]

[#function isOutputSection name section]
    [#return (outputs[name].Sections[section])?? ]
[/#function]

[#function getOutputFormat name]
    [#return outputs[name].Format ]
[/#function]

[#function getOutputContent name section="default"]
    [#return (outputs[name].Sections[section].Content)!{} ]
[/#function]

[#function getOutputAttributes name]
    [#return (outputs[name].Attributes)!{} ]
[/#function]

[#function wasOutputContentAdded name]
    [#return outputs[name].ContentAdded!false ]
[/#function]

[#function serialiseOutput name]
    [#local serialiser = outputs[name].Serialiser ]
    [#if (outputs[name].ContentAdded!false) && serialiser?has_content]
        [#-- Output is serialisable --]
        [#return invokeFunction(serialiser, outputs[name]) /]
    [/#if]
    [#return ""]
[/#function]

[#-- OUTPUT_TEXT_FORMAT --]

[#function isTextOutput name]
    [#return (getOutputAttributes(name).IsText)!false]
[/#function]

[#macro addToTextOutput name lines=[] section="default" treatAsContent=true]
    [@addOutputContent
        name=name
        content=asArray(lines)
        section=section
        treatAsContent=treatAsContent
    /]
[/#macro]

[#function formatCommentsForTextOutput name lines=[] ]
    [#local comments = [] ]
    [#local marker = getOutputAttributes(name).CommentMarker!""]
    [#if lines?has_content]
        [#list asArray(lines) as line]
            [#local comments += [marker + line] ]
        [/#list]
    [/#if]
    [#return comments]
[/#function]

[#macro addMessagesToTextOutput name messages=[] section="zzzfooter" ]
    [#if messages?has_content]
        [#local comments =
            [
                    "",
                    "--HamletMessages",
                    ""
            ] ]
        [#list messages as message]
            [#local timestamp = message.Timestamp?right_pad(30) ]
            [#local severity = "[" + message.Severity?right_pad(6) + "]" ]
            [#local comments += [[timestamp, severity, getJSON(message.Message)]?join(" ")] ]
            [#if message.Context?has_content]
                [#local comments += [" .... " + severity + " " + getJSON(message.Context)] ]
            [/#if]
            [#if message.Detail?has_content]
                [#local comments += [" .... " + severity + " " + getJSON(message.Detail)] ]
            [/#if]
        [/#list]
        [@addOutputContent
            name=name
            content=formatCommentsForTextOutput(name, comments)
            section=section
            treatAsContent=true
        /]
    [/#if]
[/#macro]

[#macro initialiseTextOutput name format=OUTPUT_TEXT_FORMAT headerLines=[] commentMarker="#" ]
    [@createOutput
        name=name
        format=format
        attributes=
            {
                "IsText" : true,
                "CommentMarker" : commentMarker
            }
        serialiser="text_output_serialiser"
    /]

    [@addOutputContent
        name=name
        section="000header"
        content=
            asArray(headerLines) +
            formatCommentsForTextOutput(
                name,
                [
                    "--Hamlet-RequestReference=${getCLORequestReference()}",
                    "--Hamlet-ConfigurationReference=${getCLOConfigurationReference()}",
                    "--Hamlet-RunId=${getCLORunId()}"
                ]
            )
        treatAsContent=false
    /]
[/#macro]

[#-- Sort the sections and then serialise as lines of text --]
[#function text_output_serialiser args=[] ]
    [#local result = "" ]

    [#local output = asFlattenedArray(args)[0] ]
    [#local sections = output.Sections?keys?sort]
    [#list sections as sectionKey]
        [#local section = output.Sections[sectionKey] ]
        [#local lines = section.Content]
        [#if section.Converter?has_content]
            [#local lines = invokeFunction(section.Converter, section.Content)]
        [/#if]
        [#if lines?is_sequence]
            [#list lines as line ]
                [#local result += line?ensure_ends_with('\n') ]
            [/#list]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#-- OUTPUT_JSON_FORMAT --]

[#function isJsonOutput name]
    [#return (getOutputAttributes(name).IsJson)!false ]
[/#function]

[#macro mergeWithJsonOutput name content={} section="default" treatAsContent=true]
    [@addOutputContent
        name=name
        section=section
        content=content
        treatAsContent=treatAsContent
        behaviour=MERGE_COMBINE_BEHAVIOUR
    /]
[/#macro]

[#macro addToJsonOutput name content={} section="default" treatAsContent=true]
    [@addOutputContent
        name=name
        section=section
        content=content
        treatAsContent=treatAsContent
    /]

[/#macro]

[#macro addMessagesToJsonOutput name messages=[] section="zzzfooter" ]
    [#if messages?has_content]
        [#local messagesAttribute = (getOutputAttributes(name).MessagesAttribute)!""]
        [#if messagesAttribute?has_content]
            [@mergeWithJsonOutput
                name=name
                section=section
                content=
                    {
                        messagesAttribute : asArray(messages)
                    }
            /]
        [/#if]
    [/#if]
[/#macro]

[#macro initialiseJsonOutput name format=OUTPUT_JSON_FORMAT messagesAttribute="" ]
    [@createOutput
        name=name
        format=format
        attributes=
            {
                "IsJson" : true
            } +
            attributeIfContent("MessagesAttribute", messagesAttribute)
        serialiser="json_output_serialiser"
    /]
[/#macro]

[#function json_output_serialiser args=[] ]
    [#local output = asFlattenedArray(args)[0] ]
    [#local sections = output.Sections?keys?sort]
    [#local result = {} ]
    [#list sections as sectionKey]
        [#local section = output.Sections[sectionKey] ]
        [#local content = section.Content]
        [#if section.Converter?has_content]
            [#local content = invokeFunction(section.Converter, section.Content)]
        [/#if]
        [#if content?is_hash]
            [#local result = mergeObjects(result, content) ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#-- Cross-format support --]
[#macro addMessagesToOutput name messages section="zzzfooter" ]
    [#if isTextOutput(name)]
        [@addMessagesToTextOutput
            name=name
            section=section
            messages=messages
        /]
    [/#if]
    [#if isJsonOutput(name)]
        [@addMessagesToJsonOutput
            name=name
            section=section
            messages=messages
        /]
    [/#if]
[/#macro]

[#-- Generate output --]

[#macro generateOutput deploymentFramework type format="" level="" include=""]

    [#list getCommandLineOptions().Output.Writers as writer ]

        [@setupOutput
            writer=writer
        /]

        [#-- Remember the output attributes to determine --]
        [#local functionOptions =
            [
                [deploymentFramework, "output", type, format],
                [DEFAULT_DEPLOYMENT_FRAMEWORK, "output", type, format]
            ] ]

        [#local outputFunction = getFirstDefinedDirective(functionOptions) ]

        [#local content = "" ]

        [#if outputFunction?has_content]
            [#local content = (.vars[outputFunction])( level, include )]
        [#else]
            [@debug
                message="Unable to invoke output function"
                context=functionOptions
                enabled=false
            /]
        [/#if]

        [#-- Check the content for inline messages --]
        [@inlineLogMessages
            content=content
        /]

        [#-- Provide the output to the writer --]
        [@writeOutput
            content=content
            writer=writer
        /]
    [/#list]
[/#macro]

[#-- Generation Contracts --]
[#assign generationcontractStepOutputMappings = {} ]
[#assign generationcontractStepOutputMappingConverters = {}]

[#macro addGenerationContractStepOutputMapping provider subset outputType outputFormat outputSuffix]
    [#assign generationcontractStepOutputMappings = mergeObjects(
                generationcontractStepOutputMappings,
                {
                    provider : {
                        subset : {
                            "Subset" : subset,
                            "OutputType" : outputType,
                            "OutputFormat" : outputFormat,
                            "OutputSuffix" : outputSuffix,
                            "OutputConversion" : "",
                            "Converters" : {}
                        }
                    }
                }
        )]
[/#macro]

[#macro addGenerationContractStepOutputMappingConverter provider id subset outputSuffix outputConversion ]
    [#assign generationcontractStepOutputMappings = mergeObjects(
            generationcontractStepOutputMappings,
            {
                provider : {
                    subset : {
                        "Converters" : {
                            id : {
                                "OutputConversion" : outputConversion,
                                "OutputSuffix" : outputSuffix
                            }
                        }
                    }
                }
            }
    )]
[/#macro]

[#function getGenerationContractStepOutputMapping providers subset converter="" ]
    [#local mapping = (getGenerationContractStepOutputMappings(providers)?filter( x -> x.Subset == subset)[0] )!{} ]
    [#if converter?has_content ]
        [#local mappingConverter = (mapping["Converters"][converter])!{} ]
        [#if mappingConverter?has_content ]
            [#local mapping = mergeObjects(mapping, mappingConverter)]
        [/#if]
    [/#if]
    [#return mapping]
[/#function]

[#function getGenerationContractStepOutputMappingFromSuffix providers suffix ]
    [#local mappings = getGenerationContractStepOutputMappings(providers) ]
    [#list mappings as mapping ]
        [#if mapping.OutputSuffix == suffix ]
            [#return mapping]
        [/#if]
        [#if ((mapping.Converters)!{})?has_content ]
            [#list mapping.Converters as converter ]
                [#if converter.OutputSuffix == suffix ]
                    [#return mergeObjects(mapping, converter)]
                [/#if]
            [/#list]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#function getGenerationContractStepOutputMappings providers ]
    [#local result = []]
    [#list providers as provider]
        [#if ((generationcontractStepOutputMappings[provider])!{})?has_content ]
            [#list generationcontractStepOutputMappings[provider] as id,subset ]
                [#local result += [ subset ]]
            [/#list]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#-- Output mappings object is extended dynamically by each resource type --]
[#assign outputMappings = {} ]

[#macro addOutputMapping provider resourceType mappings]
    [#assign outputMappings = mergeObjects(
        outputMappings,
        {
            provider : {
                resourceType : mappings
            }
        }
    )]
[/#macro]

[#function getOutputMappings provider resourceType="" attributeType=""]
    [#if resourceType?has_content]
        [#if attributeType?has_content]
            [#-- type and attribute provided, return specific attribute --]
            [#return (outputMappings[provider][resourceType][attributeType])!{}]
        [#else]
            [#-- type provided, return a specific resource type --]
            [#return (outputMappings[provider][resourceType])!{}]
        [/#if]
    [#else]
        [#-- return all provder resource mappings --]
        [#return outputMappings[provider]!{}]
    [/#if]
[/#function]

[#function getOutputFileName subset alternative converter ]

    [#local outputPrefix = getOutputFilePrefix(
                                getCLOEntranceType(),
                                getCLODeploymentGroup(),
                                getCLODeploymentUnit(),
                                subset,
                                getActiveLayer(ACCOUNT_LAYER_TYPE).Name!"",
                                contentIfContent(
                                    getCLOSegmentRegion(),
                                    getProductLayerRegion()
                                ),
                                contentIfContent(
                                    getCLOAccountRegion(),
                                    getAccountLayerRegion()
                                )
                                alternative
                            )]

    [#local outputMappings = getGenerationContractStepOutputMapping(
                                combineEntities(
                                    getLoaderProviders(),
                                    [ SHARED_PROVIDER],
                                    UNIQUE_COMBINE_BEHAVIOUR
                                ),
                                subset,
                                converter
                            )]

    [#local outputSuffix = (outputMappings["OutputSuffix"])!"" ]

    [#return formatName(outputPrefix, outputSuffix)]
[/#function]

[#function getGenerationContractProperties ]
    [#return
        {
            "entrance"               : getCLOEntranceType(),
            "flows"                  : getCLOFlows()?join(","),
            "providers"              : (getLoaderProviders()?join(","))!SHARED_PROVIDER,
            "deploymentFramework"    : getCLODeploymentFramework(),
            "deploymentUnit"         : getCLODeploymentUnit(),
            "deploymentGroup"        : getCLODeploymentGroup(),
            "account"                : getActiveLayer(ACCOUNT_LAYER_TYPE).Name!"",
            "accountRegion"          : contentIfContent(getCLOAccountRegion(), getAccountLayerRegion()),
            "region"                 : contentIfContent(getCLOSegmentRegion(),getProductLayerRegion()),
            "requestReference"       : getCLORequestReference(),
            "configurationReference" : getCLOConfigurationReference(),
            "deploymentMode"         : getDeploymentMode()
        }
    ]
[/#function]

[#function getGenerationContractStepParameters subset alternative converter templateSubset=""]
    [#local outputMappings = getGenerationContractStepOutputMapping(
                                combineEntities(
                                    getLoaderProviders(),
                                    [ SHARED_PROVIDER],
                                    UNIQUE_COMBINE_BEHAVIOUR
                                ),
                                subset,
                                converter
                            )]

    [#-- Handle Deployment Subset for generation --]
    [#local deploymentUnitSubset = subset ]
    [#if subset == "template"  ]
        [#local deploymentUnitSubset = templateSubset ]
    [/#if]

    [#if alternative == "primary"]
        [#local alternative = "" ]
    [/#if]

    [#return {
        "outputType"             : outputMappings["OutputType"],
        "outputFormat"           : outputMappings["OutputFormat"],
        "outputConversion"       : outputMappings["OutputConversion"],
        "pass"                   : subset,
        "passAlternative"        : alternative,
        "deploymentUnitSubset"   : deploymentUnitSubset,
        "outputFileName"         : getOutputFileName(subset, alternative, converter)
    }]
[/#function]

[#function getOutputFilePrefix
        entrance
        deployment_group
        deployment_unit
        deployment_subset
        account
        region
        account_region
        alternative
    ]

    [#-- set the default values for the file name parts --]
    [#local filename_parts = {
        "entrance_prefix" : entrance,
        "deployment_group_prefix" : deployment_group,
        "deployment_unit_prefix" : deployment_unit,
        "account_prefix" : account,
        "region_prefix" : region,
        "alternative_prefix" : alternative
    }]

    [#local filename_part_order = [
        "entrance_prefix",
        "deployment_group_prefix",
        "deployment_unit_prefix",
        "account_prefix",
        "region_prefix",
        "alternative_prefix"
    ]]

    [#-- Alternatives --]
    [#if filename_parts["alternative_prefix"] == "primary" ]
        [#local filename_parts =
            mergeObjects(
                filename_parts,
                {
                    "alternative_prefix" : ""
                })]
    [/#if]

    [#-- Deployment detail prefix handling --]
    [#switch entrance ]
        [#case "blueprint"]
        [#case "info"]
        [#case "loader"]
        [#case "occurrences"]
        [#case "schemalist"]
        [#case "unitlist"]
        [#case "validate"]
        [#case "imagedetails"]
        [#case "releaseinfo"]
        [#case "configuration"]
        [#case "inputinfo"]
            [#local filename_parts =
                        mergeObjects(
                            filename_parts,
                            {
                                "deployment_group_prefix" : "",
                                "deployment_unit_prefix" : ""
                            }
                        )
            ]
            [#break]
        [#case "diagram"]
            [#local filename_parts =
                        mergeObjects(
                            filename_parts,
                            {
                                "deployment_group_prefix" : ""
                            }
                        )
            ]
            [#break]

        [#case "deployment"]
        [#case "deploymenttest"]
        [#case "stackoutput"]
        [#case "buildblueprint"]
            [#break]

        [#default]
            [@fatal
                message="Output file prefix: missing deployment detail configuration"
                detail="each entrance needs to define thier requirment for deployment based information in file naming"
                context={
                    "Entrance": entrance
                }
            /]
    [/#switch]

    [#-- Deployment based prefixing --]
    [#switch entrance ]
        [#case "deployment" ]
        [#case "deploymenttest" ]
        [#case "stackoutput"]
        [#case "buildblueprint"]

            [#-- overrride the level prefix to align with older deployment groups --]
            [#local deploymentGroupDetails = getDeploymentGroupDetails(deployment_group)]
            [#local filename_parts =
                        mergeObjects(
                            filename_parts,
                            {
                                "deployment_group_prefix" : ((deploymentGroupDetails.OutputPrefix)!deploymentGroupDetails.Name)!deployment_group
                            }
                        )
            ]

            [#switch filename_parts["deployment_group_prefix"] ]
                [#case "account" ]
                    [#local filename_parts =
                                mergeObjects(
                                    filename_parts,
                                    {
                                        "entrance_prefix" : "",
                                        "region_prefix" : account_region
                                    })]

                    [#break]

                [#case "soln" ]
                [#case "seg" ]
                [#case "app" ]
                    [#local filename_parts =
                                mergeObjects(
                                    filename_parts,
                                    {
                                        "entrance_prefix" : ""
                                    })]
                    [#break]

            [/#switch]
            [#break]

        [#case "diagraminfo"]
        [#case "info"]
            [#local filename_parts =
                mergeObjects(
                    filename_parts,
                    {
                        "entrance_prefix" : "",
                        "deployment_group_prefix" : "",
                        "deployment_unit_prefix" : "",
                        "account_prefix" : "",
                        "region_prefix" : "",
                        "alternative_prefix" : ""
                    }
                )]
            [#break]

        [#case "runbook"]
        [#case "runbookinfo"]
            [#local filename_parts =
                mergeObjects(
                    filename_parts,
                    {
                        "deployment_group_prefix" : "",
                        "deployment_unit_prefix" : "",
                        "account_prefix" : "",
                        "region_prefix" :  ""
                    }
                )]
            [#break]

        [#case "schema" ]
            [#local filename_parts =
                mergeObjects(
                    filename_parts,
                    {
                        "deployment_group_prefix" : "",
                        "deployment_unit_prefix" : "",
                        "account_prefix" : "",
                        "region_prefix" :  "",
                        "entrance_prefix" : ""
                    }
                )]
            [#break]

        [#default]
            [#local filename_parts =
                mergeObjects(
                    filename_parts,
                    {
                        "account_prefix" : "",
                        "region_prefix" :  ""
                    })]
    [/#switch]

    [#local filename = "" ]

    [#list filename_part_order as part ]
        [#if ((filename_parts[part])!"")?has_content ]
            [#local filename = formatName( filename, filename_parts[part] ) ]
        [/#if]
    [/#list]

    [#return filename ]
[/#function]


[#----------------------------------------------------
-- Internal support functions for output generation --
------------------------------------------------------]

[#ftl]

[#------------------------------------------
-- Public functions for output generation --
--------------------------------------------]

[#assign OUTPUT_TEXT_FORMAT = "text"]
[#assign OUTPUT_JSON_FORMAT = "json"]

[#-- Support multiple output streams simultaneously           --]
[#-- Useful if assembling in parts e.g. resources and outputs --]
[#assign outputs = {} ]

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

[#macro serialiseOutput name]
    [#local serialiser = outputs[name].Serialiser ]
    [#if (outputs[name].ContentAdded!false) && serialiser?has_content]
        [#-- Output is serialisable --]
        [@invokeMacro serialiser outputs[name] /]
    [/#if]
[/#macro]

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
                    "--COTMessages",
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
                    "--COT-RequestReference=${commandLineOptions.References.Request}",
                    "--COT-ConfigurationReference=${commandLineOptions.References.Configuration}",
                    "--COT-RunId=${commandLineOptions.Run.Id}"
                ]
            )
        treatAsContent=false
    /]
[/#macro]

[#-- Sort the sections and then serialise as lines of text --]
[#macro text_output_serialiser args=[] ]
    [#local output = asFlattenedArray(args)[0] ]
    [#local sections = output.Sections?keys?sort]
    [#list sections as sectionKey]
        [#local section = output.Sections[sectionKey] ]
        [#local lines = section.Content]
        [#if section.Converter?has_content]
            [#local lines = invokeFunction(section.Converter, section.Content)]
        [/#if]
        [#if lines?is_sequence]
            [#list lines as line]
            ${line}
            [/#list]
        [/#if]
    [/#list]
[/#macro]

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

[#macro json_output_serialiser args=[] ]
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
    [@toJSON result /]
[/#macro]

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

    [#-- Remember the output attributes to determine --]
    [#local macroOptions =
        [
            [deploymentFramework, "output", type, format],
            [DEFAULT_DEPLOYMENT_FRAMEWORK, "output", type, format]
        ] ]

    [#local macro = getFirstDefinedDirective(macroOptions) ]

    [#if macro?has_content]
        [@(.vars[macro]) level=level include=include /]
    [#else]
        [@debug
            message="Unable to invoke output macro"
            context=macroOptions
            enabled=false
        /]
    [/#if]
[/#macro]

[#-- GENPLAN --]

[#-- Genplans leverage the general script output but add JSON based sections --]
[#-- to order steps and ensure steps aren't repeated.                        --]
[#-- Genplan sections have their own converter to convert the JSON to text   --]

[#assign genPlanStepOutputMappings = {} ]

[#macro addGenPlanStepOutputMapping provider subsets outputType outputFormat]
    [#list subsets as subset ]
        [#assign genPlanStepOutputMappings = mergeObjects(
                    genPlanStepOutputMappings,
                    {
                        provider : {
                            subset : { 
                                "OutputType" : outputType,
                                "OutputFormat" : outputFormat
                            }
                        }
                    }
            )]
    [/#list]
[/#macro]

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
            [#return outputMappings[provider][resourceType][attributeType]!{}]
        [#else]
            [#-- type provided, return a specific resource type --]
            [#return outputMappings[provider][resourceType]!{}]
        [/#if]
    [#else]
        [#-- return all provder resource mappings --]
        [#return outputMappings[provider]!{}]
    [/#if]
[/#function]

[#function getGenPlanStepOutputMapping provider subset ]
    [#if ((genPlanStepOutputMappings[provider][subset])!{})?has_content ]
        [#return genPlanStepOutputMappings[provider][subset]]
    [/#if]

    [#if ((genPlanStepOutputMappings[SHARED_PROVIDER][subset])!{})?has_content ]
        [#return genPlanStepOutputMappings[SHARED_PROVIDER][subset]]
    [/#if]

    [#return {}]
[/#function]

[#function getGenerationPlanSteps subset alternatives]

    [#-- Determine the script format --]
    [#local outputFormat = getOutputFormat(SCRIPT_DEFAULT_OUTPUT_TYPE) ]

    [#local steps = {} ]

    [#-- Determine the steps required --]
    [#list asArray(alternatives) as alternative]
        [#local step = getGenPlanStepOutputMapping( commandLineOptions.Deployment.Provider.Name, subset) ]
        [#if ! step?has_content ]
            [#return {}]
        [/#if]
        [#local step_name = [subset, alternative, commandLineOptions.Deployment.Provider.Name, commandLineOptions.Deployment.Framework.Name]?join("-") ]
        [#local steps =
            mergeObjects(
                steps,
                {
                    subset : {
                        alternative : {
                            commandLineOptions.Deployment.Provider.Name : {
                                commandLineOptions.Deployment.Framework.Name : {
                                    "Name" : step_name
                                } + step
                            }
                        }
                    }
                }
            ) ]
    [/#list]
    [#return steps]
[/#function]

[#----------------------------------------------------
-- Internal support functions for output generation --
------------------------------------------------------]

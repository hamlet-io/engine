[#ftl]

[#-- Support routines for output generation --]

[#assign OUTPUT_TEXT_FORMAT = "text"]
[#assign OUTPUT_JSON_FORMAT = "json"]

[#-- Support multiple outputs simultaneously --]
[#-- Useful if assembling in parts e.g. resources and outputs --]
[#assign outputs = {} ]

[#function isOutput name]
    [#return outputs[name]?? ]
[/#function]

[#function getOutput name]
    [#return outputs[name].Content ]
[/#function]

[#function getOutputFormat name]
    [#return outputs[name].Format ]
[/#function]

[#function wasOutputContentAdded name]
    [#return outputs[name].ContentAdded!false ]
[/#function]

[#-- Text based output --]

[#function isTextOutput name]
    [#return (outputs[name].IsText)!false]
[/#function]

[#macro addToTextOutput name lines=[] treatAsContent=true]
    [#if lines?has_content]
        [#assign outputs =
            mergeObjects(
                outputs,
                {
                    name : {
                        "Content" : outputs[name].Content + asArray(lines)
                    } +
                    attributeIfTrue("ContentAdded", treatAsContent, true)
                }
            ) ]
    [/#if]
[/#macro]

[#function formatCommentsForTextOutput name lines=[] ]
    [#local comments = [] ]
    [#if lines?has_content]
        [#list asArray(lines) as line]
            [#local comments += [outputs[name].CommentMarker + line]]
        [/#list]
    [/#if]
    [#return comments]
[/#function]

[#macro addMessagesToTextOutput name messages]
    [#if messages?has_content]
        [#local comments =
            [
                    "",
                    "--COTMessages",
                    ""
            ] ]
        [#list messages as message]
            [#local timestamp = message.Timestamp?right_pad(30) ]
            [#local severity = "[" + message.Severity?right_pad(5) + "]" ]
            [#local comments += [[timestamp, severity, getJSON(message.Message)]?join(" ")] ]
            [#if message.Context?has_content]
                [#local comments += [" ...." + getJSON(message.Context)] ]
            [/#if]
        [/#list]
        [@addToTextOutput
            name=name
            lines=formatCommentsForTextOutput(name, comments)
        /]
    [/#if]
[/#macro]

[#macro initialiseTextOutput name format=OUTPUT_TEXT_FORMAT headerLines=[] commentMarker="#" ]
    [#assign outputs +=
        {
            name : {
                "Format" : format,
                "IsText" : true,
                "CommentMarker" : commentMarker,
                "Content" : asArray(headerLines)
            }
        } ]

    [@addToTextOutput
        name=name
        lines=
            formatCommentsForTextOutput(
                name,
                [
                    "--COT-RequestReference=${requestReference}",
                    "--COT-ConfigurationReference=${configurationReference}",
                    "--COT-RunId=${runId}"
                ]
            )
        treatAsContent=false
    /]
[/#macro]

[#macro serialiseTextOutput name]
    [#list outputs[name].Content as line]
        ${line}
    [/#list]
[/#macro]

[#-- JSON based output --]

[#function isJsonOutput name]
    [#return (outputs[name].IsJson)!false ]
[/#function]

[#macro mergeWithJsonOutput name content={} treatAsContent=true]
    [#assign outputs =
        mergeObjects(
            outputs,
            {
                name : {
                    "Content" : content
                } +
                attributeIfTrue("ContentAdded", treatAsContent, true)
            }
        ) ]
[/#macro]

[#macro addToJsonOutput name content={} treatAsContent=true]
    [@mergeWithJsonOutput
        name=name
        content=outputs[name].Content + content
        treatAsContent=treatAsContent
    /]
[/#macro]

[#macro addMessagesToJsonOutput name messages=[] ]
    [#if messages?has_content]
        [#local messagesAttribute = (outputs[name].MessagesAttribute)!""]
        [#if messagesAttribute?has_content]
            [@addToJsonOutput
                name=name
                content=
                    {
                        messagesAttribute :
                            (outputs[name].Content[messagesAttribute])![] +
                            asArray(messages)
                    }
            /]
        [/#if]
    [/#if]
[/#macro]

[#macro initialiseJsonOutput name format=OUTPUT_JSON_FORMAT content={} messagesAttribute="" ]
    [#assign outputs +=
        {
            name : {
                "Format" : format,
                "IsJson" : true,
                "Content" : content
            } +
            attributeIfContent("MessagesAttribute", messagesAttribute)
        } ]
[/#macro]

[#macro serialiseJsonOutput name]
    [@toJSON outputs[name].Content /]
[/#macro]

[#-- Cross-format support --]
[#macro addMessagesToOutput name messages ]
    [#if isTextOutput(name)]
        [@addMessagesToTextOutput
            name=name
            messages=messages
        /]
    [/#if]
    [#if isJsonOutput(name)]
        [@addMessagesToJsonOutput
            name=name
            messages=messages
        /]
    [/#if]
[/#macro]

[#macro serialiseOutput name ]
    [#if wasOutputContentAdded(name)]
        [#if isTextOutput(name)]
            [@serialiseTextOutput
                name=name
            /]
        [/#if]
        [#if isJsonOutput(name)]
            [@serialiseJsonOutput
                name=name
            /]
        [/#if]
    [/#if]
[/#macro]

[#-- Generate output --]

[#macro generateOutput deploymentFramework type format="" level="" include=""]

    [#-- Remember the output attributes to determine --]
    [#local macroOptions =
        [
            [deploymentFramework, "output", type, format],
            [deploymentFramework, "output", type],
            [DEFAULT_DEPLOYMENT_FRAMEWORK, "output", type, format],
            [DEFAULT_DEPLOYMENT_FRAMEWORK, "output", type]
        ] ]

    [#local macro = getFirstDefinedDirective(macroOptions) ]

    [#if macro?has_content]
        [@(.vars[macro]) level=level include=include /]
    [#else]
        [@debug
            message="Unable to invoke output macro"
            context=templateOptions
            enabled=false
        /]
    [/#if]
[/#macro]


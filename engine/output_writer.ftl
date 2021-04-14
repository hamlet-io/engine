[#ftl]

[#-- the output writer is reponsible for determining the location and name of output files genereated by the engine --]
[#-- once it has this informaton it is then responsible for writing the content to disk --]

[#assign outputWriterConfiguration = {}]
[#assign outputHandlerConfiguration = {}]

[#assign outputProperties = {}]

[#assign outputPropertiesAttributes = [
    {
        "Names" : "type",
        "Types" : STRING_TYPE,
        "Description" : "The type of output to write",
        "Values" : [ "file", "console", "none" ],
        "Default" : "file"
    },
    {
        "Names" : "type:console",
        "Children" : [
            {
                "Names" : "stream",
                "Types" : STRING_TYPE,
                "Description" : "The console stream to write the output to",
                "Values" : [ "stdout", "stderr" ],
                "Default" : "stdout"
            }
        ]
    },
    {
        "Names" : "type:file",
        "Children" : [
            {
                "Names" : "filename",
                "Types" : STRING_TYPE,
                "Description" : "The full file name including extension for the output file",
                "Default" : ""
            },
            {
                "Names" : "directory",
                "Types" : STRING_TYPE,
                "Description" : "The directory to write the file to",
                "Default" : ""
            },
            {
                "Names" : "append",
                "Types" : BOOLEAN_TYPE,
                "Description" : "When writing append the content to the file",
                "Default" : false
            },
            {
                "Names" : "format",
                "Types" : STRING_TYPE,
                "Description" : "The format of the file to output",
                "Values" : [ "plaintext", "json", "yaml", "yml" ],
                "Default" : "plaintext"
            },
            {
                "Names" : "format:json",
                "Children" : [
                    {
                        "Names" : "formatting",
                        "Types" : STRING_TYPE,
                        "Description" : "How to format the JSON output",
                        "Values" : [ "compressed", "pretty" ],
                        "Default" : "pretty"
                    },
                    {
                        "Names" : "indentation",
                        "Types" : NUMBER_TYPE,
                        "Description" : "The space indentation applied to pretty formatting",
                        "Default" : 2
                    }
                ]
            }
        ]
    }

] ]

[#-- output hanlder functions to set the output file properties --]
[#macro setOutputProperties properties ]
    [#assign outputProperties =
            getCompositeObject(
                outputPropertiesAttributes,
                mergeObjects(outputProperties, properties )
            )]
[/#macro]

[#function getOutputProperties ]
    [#return outputProperties]
[/#function]

[#-- Add available output writer --]
[#macro addOutputWriter id properties prologueHandlers=[] epilogueHandlers=[]]
    [@internalMergeOutputWriterConfiguration
        id=id
        configuration=
            {
                "Properties" : asArray(properties),
                "PrologueHandlers" : asArray(prologueHandlers),
                "EpilogueHandlers" : asArray(epilogueHandlers)
            }
    /]
[/#macro]

[#macro addOutputHandler id properties ]
    [@internalMergeOutputHandlerConfiguration
        id=id
        configuration=
            {
                "Properties" : asArray(properties)
            }
    /]
[/#macro]

[#function getOutputWriterHandlers id handlerStage ]
    [#local result = []]

    [#if ((outputWriterConfiguration[id])!{})?has_content ]

        [#switch handlerStage?lower_case ]
            [#case "prologue" ]
                [#local result =  (outputWriterConfiguration[id].PrologueHandlers)![] ]
                [#break]

            [#case "epilogue" ]
                [#local result =  (outputWriterConfiguration[id].EpilogueHandlers)![] ]
                [#break]

        [/#switch]
    [#else]
        [@fatal
            message="Could not find specified output writer"
            context={
                "Requested" : id,
                "Avaialble" : outputWriterConfiguration?keys
            }
            enabled=true
        /]
    [/#if]

    [#return result ]
[/#function]

[#function isOutputHandlerDefined id ]
    [#return ((outputHandlerConfiguration[id])!{})?has_content ]
[/#function]

[#-- We have two stages of the output process which use handlers in essentially the same way --]
[#-- - setup - is run before we work through creating any outputs - this is where we recommend naming outputs so they can be used in output content --]
[#-- - write - is run after all outputs are run - this is where the file should be written by the engine --]

[#macro invokeOutputHandlers writer stage content={} ]
    [#local handlers = getOutputWriterHandlers(writer, stage ) ]

    [#list handlers as handler ]
        [#if ! isOutputHandlerDefined(handler) ]
            [@fatal
                message="Output handler not defined"
                context={
                    "RequestedHandler" : handler,
                    "AvailableHandlers" : outputHandlerConfiguration?keys
                }
            /]
            [#break]
        [/#if]

        [#list combineEntities( getLoaderProviders(), [ SHARED_PROVIDER ], UNIQUE_COMBINE_BEHAVIOUR) as provider ]
            [#local handlerFunctionOptions = [
                [ provider, "outputhandler", handler ]
            ]]
            [#local handlerFunction = getFirstDefinedDirective(handlerFunctionOptions)]
            [#if handlerFunction?has_content]
                [#local result = (.vars[handlerFunction])( getOutputProperties(), content) ]
                [@setOutputProperties properties=result /]
            [#else]
                [@debug
                    message="Unable to invoke output handler"
                    context=handlerFunctionOptions
                    enabled=false
                /]
            [/#if]
        [/#list]
    [/#list]
[/#macro]

[#macro setupOutput writer ]
    [@invokeOutputHandlers
        writer=writer
        stage="prologue"
    /]
[/#macro]

[#macro writeOutput content writer ]
    [@invokeOutputHandlers
        writer=writer
        stage="epilogue"
        content=content
    /]
[/#macro]

[#-- Internal macros --]
[#macro internalMergeOutputWriteState key value ]
    [#assign outputWriteState = mergeObjects(outputWriteState, { key : value })]
[/#macro]


[#macro internalMergeOutputWriterConfiguration id configuration ]
    [#assign outputWriterConfiguration =
        mergeObjects(
            outputWriterConfiguration,
            {
                id : configuration
            }
        )]
[/#macro]

[#macro internalMergeOutputHandlerConfiguration id configuration ]
    [#assign outputHandlerConfiguration =
        mergeObjects(
            outputHandlerConfiguration,
            {
                id : configuration
            }
        )]
[/#macro]

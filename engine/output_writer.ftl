[#ftl]

[#-- the output writer is reponsible for determining the location and name of output files genereated by the engine --]
[#-- once it has this informaton it is then responsible for writing the content to disk --]

[#assign outputWriterConfiguration = {}]
[#assign outputHandlerConfiguration = {}]
[#assign outputFileProperties = {} ]

[#-- output hanlder functions to set the output file properties --]
[#macro setOutputFileProperties fileprefix="" filename="" directory="" format="" ]
    [#assign outputFileProperties =
        mergeObjects(
            outputFileProperties,
            {} +
            attributeIfContent(
                "filename",
                filename
            ) +
            attributeIfContent(
                "directory",
                directory
            ) +
            attributeIfContent(
                "format",
                format
            ) +
            attributeIfContent(
                "fileprefix",
                fileprefix
            )
        )]
[/#macro]

[#function getOutputFileProperties ]
    [#return outputFilePropertiies]
[/#function]

[#function isOutputFileDefined ]
    [#return
        ((outputFileDetails["filename"])!"")?has_content
        && ((outputFileDetails["directory"])!"")?has_content
        && ((outputFileDetails["format"])!"")?has_content ]
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
[#macro setupOutput ]
    [#local handlers = getOutputWriterHandlers(commandLineOptions.OutputWriter.Id, "prologue" ) ]

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

        [#list combineEntities( commandLineOptions.Deployment.Provider.Names, [ SHARED_PROVIDER ]) as provider ]
            [#local macroOptions = [
                [ provider, "outputhandler", handler ]
            ]]
            [#local macro = getFirstDefinedDirective(macroOptions)]
            [#if macro?has_content]
                [@setOutputFileProperties?with_args((.vars[macro]) properties=getOutputFileProperties()) content=content /]
            [#else]
                [@debug
                    message="Unable to invoke output handler"
                    context=macroOptions
                    enabled=true
                /]
            [/#if]
        [/#list]
    [/#list]
[/#macro]


[#macro writeOutput content ]
    [#local handlers = getOutputWriterHandlers(commandLineOptions.OutputWriter.Id, "epilogue" ) ]

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

        [#list combineEntities( commandLineOptions.Deployment.Provider.Names, [ SHARED_PROVIDER ]) as provider ]
            [#local macroOptions = [
                [ provider, "outputhandler", handler ]
            ]]
            [#local macro = getFirstDefinedDirective(macroOptions)]
            [#if macro?has_content]
                [@setOutputFileProperties?with_args((.vars[macro]) properties=getOutputFileProperties()) content=content /]
            [#else]
                [@debug
                    message="Unable to invoke output handler"
                    context=macroOptions
                    enabled=true
                /]
            [/#if]
        [/#list]
    [/#list]

    [#if ! isOutputFileDefined() ]
        [@fatal
            message="Could not determine all file properties during output handler processing"
            context=outputFileDetails
            enabled=true
        /]
    [/#if]
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

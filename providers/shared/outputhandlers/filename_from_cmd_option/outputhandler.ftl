[#ftl]

[@addOutputHandler
    id="filename_from_cmd_option"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Get filename from command line options"
        }
    ]
/]

[#function shared_outputhandler_filename_from_cmd_option properties ]

    [#if (commandLineOptions.Output.FileName)?has_content ]
        [#local properties = mergeObjects( properties, { "filename" : commandLineOptions.Output.FileName })]
    [/#if]

    [#return properties]
[/#function]

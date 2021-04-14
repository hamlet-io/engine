[#ftl]

[@addOutputHandler
    id="write_to_console"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Log output to the console session the engine is running in"
        }
    ]
/]

[#function shared_outputhandler_write_to_console properties content ]
    [#if properties["type"] == "console" ]
        [#local consoleProperties = properties["type:console"]]
        [#local stream = consoleProperties["stream"]]

        [#if content?is_sequence || content?is_hash ]
            [#local content = getJSON(content, false, true )]
        [/#if]

        [#if content?is_number || content?is_boolean ]
            [#local content = content?c]
        [/#if]

        [#if content?has_content ]

            [#local content = content?ensure_ends_with("\n")]
            [#local result =
                toConsole(
                    content,
                    {
                    "SendTo" : stream
                    }
                )]
        [/#if]
    [/#if]
    [#return properties]
[/#function]

[#ftl]

[@addOutputHandler
    id="set_to_console"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Default the output type to console"
        }
    ]
/]

[#function shared_outputhandler_set_to_console properties content ]
    [#local properties = mergeObjects(
                            properties,
                            {
                                "type" : "console"
                            }
    )]
    [#return properties]
[/#function]

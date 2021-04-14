[#ftl]

[@addOutputHandler
    id="set_to_file"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Default the output type to file"
        }
    ]
/]

[#function shared_outputhandler_set_to_file properties content ]
    [#local properties = mergeObjects(
                            properties,
                            {
                                "type" : "file"
                            }
    )]
    [#return properties]
[/#function]

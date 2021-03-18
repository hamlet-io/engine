[#ftl]

[@addOutputHandler
    id="write_to_cmdb"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Write  to a cmdb location using the inbuilt freemarker method"
        }
    ]
/]

[#function shared_outputhandler_write_to_cmdb properties ]

    [#local fileProperties = getOutputFileProperties() ]

    [#local result = toCMDB(
        formatAbsolutePath(
            fileProperties["directory"],
            fileProperties["filename"]
        ),
        content,
        {
            "Format" : fileProperties["format"]
        }
    )]

    [#return properties]
[/#function]

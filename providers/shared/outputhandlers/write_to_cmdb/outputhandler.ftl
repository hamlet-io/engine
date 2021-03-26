[#ftl]

[@addOutputHandler
    id="write_to_cmdb"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Write to a cmdb location using the inbuilt freemarker method"
        }
    ]
/]

[#function shared_outputhandler_write_to_cmdb properties content ]

    [#local fileProperties = getOutputFileProperties() ]
    [#local fileFormat = (fileProperties["format"])!""]

    [#-- An empty JSON object is considered empty content --]
    [#-- Even if the content is empty we still write an empty file --]
    [#if ! content?has_content ]
        [#local content=""]
        [#local fileFormat=""]
    [/#if]

    [#if ((fileProperties["directory"])!"")?has_content &&
            ((fileProperties["filename"])!"")?has_content ]

        [#local result = toCMDB(
            formatAbsolutePath(
                (fileProperties["directory"])!"",
                (fileProperties["filename"])!""
            ),
            content,
            {
                "Format" : fileFormat
            }
        )]
    [/#if]
    [#return properties]
[/#function]

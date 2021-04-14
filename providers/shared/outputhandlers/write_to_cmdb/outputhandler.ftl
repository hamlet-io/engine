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

    [#if properties["type"] == "file" ]

        [#local fileProperties = properties["type:file"]]

        [#local fileFormat = fileProperties["format"]]
        [#local fileName = fileProperties["filename"]]
        [#local directory = fileProperties["directory"]]

        [#local append = fileProperties["append"]]

        [#local filePath = formatAbsolutePath(directory, fileName)]

        [#if (! (fileName?has_content)) || (! (directory?has_content)) ]
            [@fatal
                message="Required file properties not available for file output"
                detail="file name and directory must be provided"
                context=properties
            /]
        [/#if]

        [#-- An empty JSON object is considered empty content --]
        [#-- Even if the content is empty we still write an empty file --]
        [#if ! (content?has_content) ]
            [#local content = ""]
            [#local fileFormat = "plaintext"]
        [/#if]

        [#-- Override file paramters based on file format--]
        [#local fileParameters = {
            "Format" : fileFormat,
            "Append" : append
        }]

        [#switch (fileFormat)?lower_case ]
            [#case "json" ]
                [#local jsonFormatProperties = fileProperties["format:json"]]

                [#local fileParameters = mergeObjects(
                                            fileParameters,
                                            {
                                                "Formatting" : jsonFormatProperties["formatting"],
                                                "Indent" : jsonFormatProperties["indentation"]
                                            }
                )]
                [#break]
        [/#switch]

        [#if directory?has_content && fileName?has_content ]
            [#local result = toCMDB(
                filePath,
                content,
                fileParameters
            )]
        [/#if]
    [/#if]
    [#return properties]
[/#function]

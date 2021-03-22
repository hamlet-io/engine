[#ftl]

[@addOutputHandler
    id="filepath_from_cmd_option"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Get filename from command line options. The assumes that something has explictly set the filename like a generation contract"
        }
    ]
/]

[#function shared_outputhandler_filepath_from_cmd_option properties content ]

    [#if (commandLineOptions.Output.FileName)?has_content ]
        [#local properties = mergeObjects( properties, { "filename" : commandLineOptions.Output.FileName })]
    [/#if]

    [#if (commandLineOptions.Output.Directory)?has_content ]
        [#local cmdbs = getCMDBs({"ActiveOnly" : true}) ]
        [#list cmdbs as cmdb ]
            [#if cmdb.FileSystemPath == commandLineOptions.Output.Directory]
                [#local properties = mergeObjects( properties, { "directory" : cmdb.CMDBPath })]
            [/#if]
        [/#list]
    [/#if]

    [@debug message="FilePath" context=properties enabled=true /]

    [#return properties]
[/#function]

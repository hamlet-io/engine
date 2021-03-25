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

    [#if (getCommandLineOptions().Output.FileName)?has_content ]
        [#local properties = mergeObjects( properties, { "filename" : getCommandLineOptions().Output.FileName })]
    [/#if]

    [#if (getCommandLineOptions().Output.Directory)?has_content ]
        [#local cmdbs = getCMDBs({"ActiveOnly" : true}) ]
        [#list cmdbs as cmdb ]
            [#if cmdb.FileSystemPath == getCommandLineOptions().Output.Directory]
                [#local properties = mergeObjects( properties, { "directory" : cmdb.CMDBPath })]
            [/#if]
        [/#list]
    [/#if]
    [#return properties]
[/#function]

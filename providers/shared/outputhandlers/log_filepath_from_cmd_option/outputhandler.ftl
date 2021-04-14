[#ftl]

[@addOutputHandler
    id="log_filepath_from_cmd_option"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Get filename from command line options. The assumes that something has explictly set the filename like a generation contract"
        }
    ]
/]

[#function shared_outputhandler_log_filepath_from_cmd_option properties content ]

    [#if (getCommandLineOptions().Logging.FileName)?has_content ]
        [#local properties = mergeObjects(
                                properties,
                                {
                                    "type:file" : {
                                        "filename" : getCommandLineOptions().Logging.FileName
                                    }
                                }
                            )]
    [/#if]

    [#if (getCommandLineOptions().Logging.Directory)?has_content ]
        [#local cmdbs = getCMDBs({"ActiveOnly" : true}) ]
        [#list cmdbs as cmdb ]
            [#if cmdb.FileSystemPath == getCommandLineOptions().Logging.Directory]
                [#local properties = mergeObjects(
                                        properties,
                                        {
                                            "type:file" : {
                                                "directory" : cmdb.CMDBPath
                                            }
                                        }
                                    )]
            [/#if]
        [/#list]
    [/#if]
    [#return properties]
[/#function]

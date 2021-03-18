[#ftl]

[@addOutputHandler
    id="setup_cmdb"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Initilise the cmdb ready for output usage"
        }
    ]
/]

[#function shared_outputhandler_setup_cmdb properties ]
    [#local result = initialiseCMDBFileSystem({}) ]
    [#return properties ]
[/#function]

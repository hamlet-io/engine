[#ftl]

[@addOutputWriter
    id="output_dir"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Output to a directory provided as a command line option"
            }
        ]
    handlers=[
        "setup_cmdb",
        "write_to_cmdb"
    ]
/]

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
    prologueHandlers=[
        "setup_cmdb",
        "filename_from_cmd_option"
    ]

    epilogueHandlers=[
        "write_to_cmdb"
    ]
/]

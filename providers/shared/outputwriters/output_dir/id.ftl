[#ftl]

[@addOutputWriter
    id="output_dir"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Output to a file and directory provided as a command line option"
            }
        ]
    prologueHandlers=[
        "set_to_file",
        "setup_cmdb",
        "filepath_from_cmd_option"
    ]

    epilogueHandlers=[
        "write_to_cmdb"
    ]
/]

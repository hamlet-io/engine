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
        "filepath_from_cmd_option",
        "filename_from_base_options"
    ]

    epilogueHandlers=[
        "write_to_cmdb"
    ]
/]

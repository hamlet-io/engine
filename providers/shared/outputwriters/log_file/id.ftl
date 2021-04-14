[#ftl]

[@addOutputWriter
    id="log_file"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Write output to a log file"
            }
        ]
    prologueHandlers=[
        "set_to_file",
        "setup_cmdb",
        "log_filepath_from_cmd_option"
    ]
    epilogueHandlers=[
        "write_to_cmdb"
    ]
/]

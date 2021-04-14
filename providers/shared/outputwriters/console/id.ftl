[#ftl]

[@addOutputWriter
    id="console"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Output to the terminal console"
            }
        ]
    prologueHandlers=[
        "set_to_console"
    ]
    epilogueHandlers=[
        "write_to_console"
    ]
/]

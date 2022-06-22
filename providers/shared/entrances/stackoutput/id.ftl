[#ftl]

[@addEntrance
    type=STACKOUTPUT_ENTRANCE_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Writes the provided content as a stack output"
            }
        ]
    commandlineoptions=[
        {
            "Names" : "StackOutputContent",
            "Description" : "A JSON escaped string that will be used as the contents of the output file",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "*",
            "Types" : ANY_TYPE
        }
    ]
/]

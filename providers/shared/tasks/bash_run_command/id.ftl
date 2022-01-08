[#ftl]

[@addTask
    type=BASH_RUN_COMMAND_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Run a bash command locally and use the stdout as the returned result"
            }
        ]
    attributes=[
        {
            "Names" : "Command",
            "Description" : "The command to run",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

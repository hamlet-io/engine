[#ftl]

[@addTask
    type=RUN_BASH_SCRIPT_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Execute a shell script"
            }
        ]
    attributes=[
        {
            "Names" : "scriptFileName",
            "Description" : "The name of the script to run",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "source",
            "Description" : "Source the script when executing it as part of the executor process",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        }
    ]
/]

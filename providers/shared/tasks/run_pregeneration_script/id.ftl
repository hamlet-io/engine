[#ftl]

[@addTask
    type=RUN_PREGENERATION_SCRIPT_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Executes a script as part the template generation process"
            }
        ]
    attributes=[
        {
            "Names" : "scriptFileName",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

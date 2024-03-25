[#ftl]

[@addTask
    type=FILE_PATH_DETAILS_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Return an output with details on a given filepath namely its type and if it exists"
            }
        ]
    attributes=[
        {
            "Names" : "FilePath",
            "Description" : "The path to the file",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

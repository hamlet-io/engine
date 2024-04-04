[#ftl]

[@addTask
    type=FILE_DELETE_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Deletes a file if it is a file and is present"
            }
        ]
    attributes=[
        {
            "Names" : "FilePath",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

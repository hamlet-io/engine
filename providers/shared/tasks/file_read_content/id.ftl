[#ftl]

[@addTask
    type=FILE_READ_CONTENT_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Read the contents of a file and provide the content as a result output"
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

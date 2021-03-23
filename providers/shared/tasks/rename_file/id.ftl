[#ftl]

[@addTask
    type=RENAME_FILE_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Renames a file to a new value within the same directory"
            }
        ]
    attributes=[
        {
            "Names" : "currentFileName",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "newFileName",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

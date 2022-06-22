[#ftl]

[@addTask
    type=FILE_ZIP_PATH_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Crate a zip based archive of a source path and save it to the destination path. If already a zip then copy to destination"
            }
        ]
    attributes=[
        {
            "Names" : "SourcePath",
            "Description" : "The path to the directory to zip or an existing zip",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "DestinationPath",
            "Description" : "The path to output the zip to",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

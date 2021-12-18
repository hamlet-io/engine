[#ftl]

[@addTask
    type=CREATE_SCHEMA_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Create a JSONSchema for a give schema set"
            }
        ]
    attributes=[
        {
            "Names" : "Schema",
            "Description" : "The schema to generate",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

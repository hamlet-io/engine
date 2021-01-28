[#ftl]

[@addTask
    type=CREATE_SCHEMASET_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Generate a schemacontract for a given data type."
            }
        ]
    attributes=[
        {
            "Names" : "SchemaType",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "SchemaInstance",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

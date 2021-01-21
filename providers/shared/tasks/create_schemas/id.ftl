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
            "Names" : "DeploymentUnit",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "DeploymentGroup",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "DeploymentProvider",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

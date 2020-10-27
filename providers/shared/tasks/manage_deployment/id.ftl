[#ftl]

[@addTask
    type=MANAGE_DEPLOYMENT_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Generate a list of deployment units and groups that can be used to manage a segment"
            }
        ]
    attributes=[
        {
            "Names" : "DeploymentUnit",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "DeploymentGroup",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Operations",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "DeploymentProvider",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

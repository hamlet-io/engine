[#ftl]

[@addTask
    type=CMDB_WRITE_STACK_OUTPUT
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Write a stack output as part of a runbook"
            }
        ]
    attributes=[
        {
            "Names" : "StackOutputContent",
            "Description" : "The key value parirs to write to the file as a JSON escaped string",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "DeploymentUnit",
            "Description" : "The deployment unit the stack belongs to",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "DeploymentGroup",
            "Description" : "The deployment group the stack belongs to",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names": "GenerationFramework",
            "Description" : "The framework to use for generating the template",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "GenerationProviders",
            "Description" : "A list of generation providers used for the engine",
            "Types": STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "GenerationInputSource",
            "Description" : "The input source used for te engine",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
        {
            "Names" : "RootDir",
            "Description" : "The CMDB root directory path",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "DistrictType",
            "Description" : "The type of district used in the deployment",
            "Types" : STRING_TYPE,
            "Mandatory": true
        },
        {
            "Names": "Tenant",
            "Description" : "The Name of the tenant layer",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names": "Account",
            "Description" : "The Name of the account layer",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names": "Product",
            "Description" : "The Name of the product layer",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names": "Environment",
            "Description" : "The Name of the environment layer",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names": "Segment",
            "Description" : "The Name of the segment layer",
            "Types" : STRING_TYPE,
            "Default" : ""
        }
    ]
/]

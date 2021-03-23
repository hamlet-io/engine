[#ftl]

[@addTask
    type=PROCESS_TEMPLATE_PASS_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Execute the codeontap freemarker engine to create an occurrence template file for subset"
            }
        ]
    attributes=[
        {
            "Names" : "entrance",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "flows",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "providers",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "deploymentFramework",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "outputType",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "outputFormat",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "pass",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "passAlternative",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "outputFileName",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "deploymentUnit",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "deploymentUnitSubset",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "deploymentGroup",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "resourceGroup",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "account",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "accountRegion",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "region",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "requestReference",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "configurationReference",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "deploymentMode",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

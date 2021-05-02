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
            "Names" : "outputConversion",
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
            "Names" : "deploymentUnitSubset",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

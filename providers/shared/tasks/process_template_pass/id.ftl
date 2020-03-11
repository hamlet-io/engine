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
            "Names" : "provider",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "framework",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "outputType",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "outputFormat",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "outputSuffix",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "subset",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "alternative",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

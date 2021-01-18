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
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "framework",
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
            "Names" : "outputSuffix",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "subset",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "alternative",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

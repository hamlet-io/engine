[#ftl]

[@addTask
    type=OUTPUT_ECHO_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Echo the provided value to stdout or stderr"
            }
        ]
    attributes=[
        {
            "Names" : "Value",
            "Description" : "The value to echo",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Format",
            "Description" : "The format of the data to output - pretty prints if possible",
            "Types" : STRING_TYPE,
            "Values" : [ "string", "json" ],
            "Default" : "string"
        },
        {
            "Names" : "OutputStream",
            "Description" : "The stream to output the value to",
            "Types" : STRING_TYPE,
            "Values" : [ "stdout", "stderr"],
            "Default" : "stdout"
        }
    ]
/]

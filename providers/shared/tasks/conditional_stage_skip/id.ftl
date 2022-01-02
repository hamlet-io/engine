[#ftl]

[@addTask
    type=CONDITIONAL_STAGE_SKIP_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "If a condition doesn't match skip the rest of the steps in the stage"
            }
        ]
    attributes=[
        {
            "Names" : "Test",
            "Description" : "The value compared to",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Condition",
            "Description" : "How to test the value",
            "Types" : STRING_TYPE,
            "Values" : [ "Equals", "StartsWith", "EndsWith", "Contains" ],
            "Mandatory" : true
        }
        {
            "Names" : "Value",
            "Description" : "The value to test the match on",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

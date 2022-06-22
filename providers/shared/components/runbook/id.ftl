[#ftl]

[@addComponent
    type=RUNBOOK_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A series of tasks to perform using other deployed components"
            },
            {
                "Type" : "Note",
                "Value" : "Runbooks do not have deployments and are instead generated through the runbook entrance"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Description" : "The engine that will execute the runbook",
                "Values" : [ "hamlet" ],
                "Default" : "hamlet"
            },
            {
                "Names" : "Inputs",
                "Description" : "Inputs can be provided by users to start the runbook with different options",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Default",
                        "Description" : "The default value of the input",
                        "Types" : ANY_TYPE
                    },
                    {
                        "Names" : "Mandatory",
                        "Description"  : "If the input must be provided",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "Values",
                        "Description" : "Restricts the provided value to one of these values",
                        "Types" : ARRAY_OF_ANY_TYPE
                    },
                    {
                        "Names" : "Types",
                        "Description" : "The supported types of the input",
                        "Values" : [
                            ARRAY_TYPE,
                            OBJECT_TYPE,
                            STRING_TYPE,
                            BOOLEAN_TYPE
                        ],
                        "Types" : ARRAY_OF_STRING_TYPE
                    }
                ]
            }
        ]
/]

[@addChildComponent
    type=RUNBOOK_STEP_COMPONENT_TYPE
    parent=RUNBOOK_COMPONENT_TYPE
    childAttribute="Steps"
    linkAttributes="RunBookStep"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A step to perform as part of a runbook"
            }
        ]
    attributes=[
        {
            "Names" : "Priority",
            "Description" : "The priority order for the step to run (lowest first)",
            "Types" : NUMBER_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Conditions",
            "Description" : "All conditions for a step must pass to run the step",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Value",
                    "Description" : "The value to compare the test to",
                    "Types" : [
                        STRING_TYPE,
                        BOOLEAN_TYPE
                    ],
                    "Mandatory" : true
                },
                {
                    "Names" : "Match",
                    "Description" : "How to match the value of the setting",
                    "Types" : STRING_TYPE,
                    "Values" : [
                        "Contains",
                        "Equals",
                        "StartsWith",
                        "EndsWith",
                        "NotEquals"
                    ],
                    "Default" : "Equals"
                },
                {
                    "Names" : "Test",
                    "Description" : "The test to match the value against",
                    "Types" : [
                        STRING_TYPE,
                        BOOLEAN_TYPE
                    ]
                }
            ]
        },
        {
            "Names" : "Extensions",
            "Description" : "Extensions to invoke to provide task Parameters",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "Task",
            "Children" : [
                {
                    "Names" : "Type",
                    "Description" : "The type of the task to run in the step",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Parameters",
                    "Description" : "The parameters required to run the task type",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names": "Value",
                            "Description" : "The value of the parameter (supports substitution syntax)",
                            "Mandatory" : true,
                            "Types" : [ STRING_TYPE, NUMBER_TYPE, BOOLEAN_TYPE ]
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Links",
            "SubObjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        }
    ]
/]

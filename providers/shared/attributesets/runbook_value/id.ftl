[#ftl]

[@addAttributeSet
    type=RUNBOOK_VALUE_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "The source of a value to use as part of runbooks"
        }]
    attributes=[
        {
            "Names" : "Source",
            "Description" : "Where to get the value from",
            "Values" : [ "Setting", "Attribute", "Input", "Output", "Fixed" ],
            "Mandatory" : true
        },
        {
            "Names" : "source:Setting",
            "Children" : [
                {
                    "Names" : "Name",
                    "Description" : "The name of the step setting",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "source:Attribute",
            "Children" : [
                {
                    "Names" : "LinkId",
                    "Description" : "The id of a link in Links that the attribute will come from",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Name",
                    "Description" : "The name of the attribute from the links attributes",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "source:Input",
            "Children" : [
                {
                    "Names" : "Id",
                    "Description" : "The Id of an input provided to the parent runbook",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "source:Output",
            "Children" : [
                {
                    "Names" : "StepId",
                    "Description" : "The Id of the step to use for the output",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Name",
                    "Description" : "The name of an output provided by the step",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "source:Fixed",
            "Children" : [
                {
                    "Names" : "Value",
                    "Description" : "A fixed value to use",
                    "Types" : [ STRING_TYPE, NUMBER_TYPE, BOOLEAN_TYPE, ARRAY_OF_STRING_TYPE, ARRAY_OF_NUMBER_TYPE]
                }
            ]
        }
    ]
/]

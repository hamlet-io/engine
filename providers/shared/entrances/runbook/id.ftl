[#ftl]

[@addEntrance
    type=RUNBOOK_ENTRANCE_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Creates a runbook contract to perform tasks using components"
            }
        ]
    commandlineoptions=[
        {
            "Names" : "RunBook",
            "Description" : "The TypedRawName of the run book to create a contract from",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "RunBookInputs",
            "Description" : "A JSON escaped string that will be exanded to the inputs of the runbook",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "*",
            "Types" : ANY_TYPE
        }
    ]
/]

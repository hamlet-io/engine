[#ftl]

[@addEntrance
    type=SCHEMASET_ENTRANCE_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Generates Schema Contracts that are used to generate all JSONSchema files by their data type."
            }
        ]
    commandlineoptions=[
        {
            "Names" : "*",
            "Type" : ANY_TYPE
        }
    ]
/]

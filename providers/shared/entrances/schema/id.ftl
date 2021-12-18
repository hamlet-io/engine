[#ftl]

[@addEntrance
    type=SCHEMA_ENTRANCE_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Povides JSON schema representations of input configuration"
            }
        ]
    commandlineoptions=[
        {
            "Names" : "Schema",
            "Description" : "A regex pattern to match the schema name of an available schema",
            "Types" : STRING_TYPE,
            "Default" : ".*"
        }
    ]
/]

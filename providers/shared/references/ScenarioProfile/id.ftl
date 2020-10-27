[#ftl]

[@addReference
    type=SCENARIOPROFILE_REFERENCE_TYPE
    pluralType="ScenarioProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of scenarios and parameters to load into a generation"
            }
        ]
    attributes=[
        {
            "Names" : "Scenarios",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Description" : "To enable loading the scenario in this profile",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                }
                {
                    "Names" : "Provider",
                    "Description" : "The provider name which offers the scenario",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Name",
                    "Description" : "The name of the scneario to load",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Parameters",
                    "Description" : "The parameter values to provide to the scenario",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Key",
                            "Type" : STRING_TYPE,
                            "Description" : "The key of the parameter",
                            "Mandatory" : true
                        },
                        {
                            "Names" : "Value",
                            "Type" : ANY_TYPE,
                            "Description" : "The value of the parameter",
                            "Mandatory" : true
                        }
                    ]
                }
            ]
        }
    ]
/]

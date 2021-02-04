[#ftl]

[@addReference
    type=TESTCASE_REFERENCE_TYPE
    pluralType="TestCases"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "An output test case"
            }
        ]
    attributes=[
        {
            "Names" : "OutputSuffix",
            "Types" : STRING_TYPE,
            "Values" : [
                "template.json",
                "config.json",
                "cli.json",
                "parameters.json",
                "prologue.sh",
                "epilogue.sh"
            ]
        },
        {
            "Names" : "Structural",
            "Children" : [
                {
                    "Names" : "JSON",
                    "Description" : "Generic JSON level structure tests",
                    "Children" : [
                        {
                            "Names" : "Match",
                            "Description" : "Does a JSON path match a value",
                            "SubObjects" : true,
                            "Children" : [
                                {
                                    "Names" : "Path",
                                    "Types" : STRING_TYPE
                                },
                                {
                                    "Names" : "Value",
                                    "Types" : ANY_TYPE
                                }
                            ]
                        },
                        {
                            "Names" : "Length",
                            "Description" : "Length of an Array at a given JSON path",
                            "SubObjects" : true,
                            "Children" : [
                                {
                                    "Names" : "Path",
                                    "Types" : STRING_TYPE
                                },
                                {
                                    "Names" : "Count",
                                    "Types" : NUMBER_TYPE
                                }
                            ]
                        },
                        {
                            "Names" : "Exists",
                            "Description" : "Does a JSON path exist",
                            "Types" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "NotEmpty",
                            "Description" : "Is the value of a JSON path not emtpy",
                            "Types" : ARRAY_OF_STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "CFN",
                    "Description" : "Cloud formation Template structure",
                    "Children" : [
                        {
                            "Names" : "Resource",
                            "Description" : "Does a resource with the type exist",
                            "SubObjects" : true,
                            "Children" : [
                                {
                                    "Names" : "Name",
                                    "Mandatory" : true,
                                    "Types" : STRING_TYPE
                                },
                                {
                                    "Names" : "Type",
                                    "Mandatory" : true,
                                    "Types" : STRING_TYPE
                                }
                            ]
                        },
                        {
                            "Names" : "Output",
                            "Description" : "Does an output with exist",
                            "Types" : ARRAY_OF_STRING_TYPE
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Tools",
            "Description" : "Tool based tests - linters etc",
            "Children" : [
                {
                    "Names" : "CFNLint",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "CFNNag",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        }
    ]
/]

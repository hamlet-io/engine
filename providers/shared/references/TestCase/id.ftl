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
            "Type" : STRING_TYPE,
            "Values" : [ "template" ]
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
                                    "Type" : STRING_TYPE
                                },
                                {
                                    "Names" : "Value",
                                    "Type" : ANY_TYPE
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
                                    "Type" : STRING_TYPE
                                },
                                {
                                    "Names" : "Count",
                                    "Type" : NUMBER_TYPE
                                }
                            ]
                        },
                        {
                            "Names" : "Exists",
                            "Description" : "Does a JSON path exist",
                            "Type" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "NotEmpty",
                            "Description" : "Is the value of a JSON path not emtpy",
                            "Type" : ARRAY_OF_STRING_TYPE
                        }
                    ]
                }
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
                                    "Type" : STRING_TYPE
                                },
                                {
                                    "Names" : "Type",
                                    "Mandatory" : true,
                                    "Type" : STRING_TYPE
                                }
                            ]
                        },
                        {
                            "Names" : "Output",
                            "Description" : "Does an output with exist",
                            "Type" : ARRAY_OF_STRING_TYPE
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
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "CFNNag",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        }
    ]
/]

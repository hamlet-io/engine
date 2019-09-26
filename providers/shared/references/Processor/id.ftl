[#ftl]

[@addReference 
    type=PROCESSOR_REFERENCE_TYPE
    pluralType="Processors"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Compute resources and hardware type" 
            }
        ]
    attributes=[
        {
            "Names" : "*",
            "Children" : [ 
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "MinPerZone",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "MaxPerZone",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "DesiredPerZone",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "CountPerZone",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "MaxCount",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "MinCount",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "DesiredCount",
                    "Type" : NUMBER_TYPE
                }
            ]
        }
    ]
/]
[#ftl]

[#assign nodeCountChildConfiguration =
    [
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
]

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
            "Names" : "NAT",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : [ "bastion", "SSH" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "EC2",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "ECS",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : "ComputeCluster",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : [ "db", "RDS" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : [ "cache", "ElastiCache" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "CountPerZone",
                    "Type" : NUMBER_TYPE,
                    "Default" : 1
                }
            ]
        },
        {
            "Names" : [ "es", "ElasticSearch" ],
            "Children" : [
                {
                    "Names" : [ "Processor", "DataNodeProcessor" ],
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : [ "CountPerZone", "DataNodeCountPerZone" ],
                    "Type" : NUMBER_TYPE,
                    "Default" : 1
                },
                {
                    "Names" : "Master",
                    "Children" : [
                        {
                            "Names" : "Processor",
                            "Type" : STRING_TYPE
                        },
                        {
                            "Names" : "Count",
                            "Type" : NUMBER_TYPE,
                            "Default" : 0
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "service",
            "Children" : nodeCountChildConfiguration
        },
        {
            "Names" : "EMR",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "DesiredCorePerZone",
                    "Type" : NUMBER_TYPE,
                    "Default" : 1
                },
                {
                    "Names" : "DesiredTaskPerZone",
                    "Type" : NUMBER_TYPE,
                    "Default" : 1
                }
            ]
        }
    ]
/]

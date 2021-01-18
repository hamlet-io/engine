[#ftl]

[#assign nodeCountChildConfiguration =
    [
        {
            "Names" : "MinPerZone",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "MaxPerZone",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "DesiredPerZone",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "MaxCount",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "MinCount",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "DesiredCount",
            "Types" : NUMBER_TYPE
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
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : [ "bastion", "SSH" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "EC2",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "ECS",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : "containerhost",
            "Children" : nodeCountChildConfiguration
        },
        {
            "Names" : "ComputeCluster",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : [ "db", "RDS" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : [ "cache", "ElastiCache" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "CountPerZone",
                    "Types" : NUMBER_TYPE,
                    "Default" : 1
                }
            ]
        },
        {
            "Names" : [ "es", "ElasticSearch" ],
            "Children" : [
                {
                    "Names" : [ "Processor", "DataNodeProcessor" ],
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : [ "CountPerZone", "DataNodeCountPerZone" ],
                    "Types" : NUMBER_TYPE,
                    "Default" : 1
                },
                {
                    "Names" : "Master",
                    "Children" : [
                        {
                            "Names" : "Processor",
                            "Types" : STRING_TYPE
                        },
                        {
                            "Names" : "Count",
                            "Types" : NUMBER_TYPE,
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
            "Names" : "containerservice",
            "Children" : nodeCountChildConfiguration
        },
        {
            "Names" : "EMR",
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "DesiredCorePerZone",
                    "Types" : NUMBER_TYPE,
                    "Default" : 1
                },
                {
                    "Names" : "DesiredTaskPerZone",
                    "Types" : NUMBER_TYPE,
                    "Default" : 1
                }
            ]
        }
    ]
/]

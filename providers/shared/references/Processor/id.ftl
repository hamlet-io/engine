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
            "Names" : ["nat", "NAT"],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : ["bastion", "SSH"],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : ["ec2", "EC2"],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : ["ecs", "ECS"],
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
            "Names" : ["computecluster", "ComputeCluster" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : [ "db", "DB", "rds", "RDS" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : [ "docdb" ],
            "Children" : [
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE
                }
            ] +
            nodeCountChildConfiguration
        },
        {
            "Names" : ["cache", "ElastiCache"],
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
            "Names" : ["es", "ElasticSearch"],
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
            "Names" : ["service", "Service"],
            "Children" : nodeCountChildConfiguration
        },
        {
            "Names" : ["containerservice", "ContainerService" ],
            "Children" : nodeCountChildConfiguration
        },
        {
            "Names" : ["emr", "EMR"],
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

[#ftl]

[@addReference
    type=LOGFILEPROFILE_REFERENCE_TYPE
    pluralType="LogFileProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collectio of log file groups based on component type"
            }
        ]
    attributes=[
        {
            "Names" : ["bastion", "ssh", "Bastion"],
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "LogFileGroups",
                    "Types" : ARRAY_OF_STRING_TYPE
                }
            ]
        },
        {
            "Names" : ["computecluster", "ComputeCluster"],
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "LogFileGroups",
                    "Types" : ARRAY_OF_STRING_TYPE
                }
            ]
        },
        {
            "Names" : ["ec2", "EC2"],
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "LogFileGroups",
                    "Types" : ARRAY_OF_STRING_TYPE
                }
            ]
        },
        {
            "Names" : ["ecs", "ECS"],
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "LogFileGroups",
                    "Types" : ARRAY_OF_STRING_TYPE
                }
            ]
        }
    ]
/]

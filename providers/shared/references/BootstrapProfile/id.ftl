[#ftl]

[@addReference
    type=BOOTSTRAPPROFILE_REFERENCE_TYPE
    pluralType="BootstrapProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of boostraps to apply"
            }
        ]
    attributes=[
        {
            "Names" : ["bastion", "Bastion", "ssh"],
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "Bootstraps",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : ["computecluster", "ComputeCluster"],
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "Bootstraps",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : ["ec2", "EC2" ],
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "Bootstraps",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : ["ecs", "ECS"],
            "Description" : "The component type the profile applies to",
            "Children" : [
                {
                    "Names" : "Bootstraps",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
    ]
/]

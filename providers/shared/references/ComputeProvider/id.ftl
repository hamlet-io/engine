[#ftl]

[@addReference
    type=COMPUTEPROVIDER_REFERENCE_TYPE
    pluralType="ComputeProviders"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Policies to determine the compute services used to host a given resource"
            }
        ]
    attributes=[
        {
            "Names" : "Containers",
            "Description" : "Compute policy for container based resources",
            "Children" : [
                {
                    "Names" : "Default",
                    "Description" : "Sets the default computer provider which will meet base capacity",
                    "Children" : [
                        {
                            "Names" : "Provider",
                            "Description" : "The default container compute provider",
                            "Type"  : STRING_TYPE,
                            "Values" : [ "_autoscalegroup", "aws:fargate", "aws:fargatespot" ],
                            "Default" : "_autoscalegroup"
                        },
                        {
                            "Names" : "Weight",
                            "Type" : NUMBER_TYPE,
                            "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                            "Default" : 1
                        },
                        {
                            "Names" : "RequiredCount",
                            "Description" : "The minimum count of containers to run on the default provider",
                            "Type" : NUMBER_TYPE,
                            "Default" : 1
                        }
                    ]
                },
                {
                    "Names" : "Additional",
                    "Description" : "Providers who will meet the additonal compute capacity outside of the default",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Provider",
                            "Type" : STRING_TYPE,
                            "Values" : [ "_autoscalegroup", "aws:fargate", "aws:fargatespot" ],
                            "Mandatory" : true
                        },
                        {
                            "Names" : "Weight",
                            "Type" : NUMBER_TYPE,
                            "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                            "Default" : 1
                        }
                    ]
                }
            ]
        }
    ]
/]

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
                    "Names" : "Providers",
                    "Description" : "The providers that are available",
                    "Types"  : ARRAY_OF_STRING_TYPE,
                    "Values" : [ "_autoscalegroup", "aws:fargate", "aws:fargatespot" ],
                    "Default" : [ "_autoscalegroup", "aws:fargate", "aws:fargatespot" ]
                },
                {
                    "Names" : "Default",
                    "Description" : "Sets the default computer provider which will meet base capacity",
                    "Children" : [
                        {
                            "Names" : "Provider",
                            "Description" : "The default container compute provider",
                            "Types"  : STRING_TYPE,
                            "Values" : [ "_autoscalegroup", "aws:fargate", "aws:fargatespot" ],
                            "Default" : "_autoscalegroup"
                        },
                        {
                            "Names" : "Weight",
                            "Types" : NUMBER_TYPE,
                            "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                            "Default" : 1
                        },
                        {
                            "Names" : "RequiredCount",
                            "Description" : "The minimum count of containers to run on the default provider",
                            "Types" : NUMBER_TYPE,
                            "Default" : 1
                        }
                    ]
                },
                {
                    "Names" : "Additional",
                    "Description" : "Providers who will meet the additional compute capacity outside of the default",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : "Provider",
                            "Types" : STRING_TYPE,
                            "Values" : [ "_autoscalegroup", "aws:fargate", "aws:fargatespot" ],
                            "Mandatory" : true
                        },
                        {
                            "Names" : "Weight",
                            "Types" : NUMBER_TYPE,
                            "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                            "Default" : 1
                        }
                    ]
                }
            ]
        }
    ]
/]

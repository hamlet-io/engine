[#ftl]

[@addExtendedAttributeSet
    type=SCALINGPOLICY_ECS_ATTRIBUTESET_TYPE
    baseType=SCALINGPOLICY_ATTRIBUTESET_TYPE
    provider=SHARED_PROVIDER
    properties=[
        {
                "Type"  : "Description",
                "Value" : "ECS Specific overrides for scaling policies"
        }]
    attributes=[
        {
            "Names" : "Type",
            "Types" : STRING_TYPE,
            "Values" : [ "Stepped", "Tracked", "Scheduled", "ComputeProvider" ],
            "Default" : "ComputeProvider"
        },
        {
            "Names" : "ComputeProvider",
            "Children": [
                {
                    "Names" : "MinAdjustment",
                    "Description" : "The minimum instances to update during scaling activities",
                    "Types" : NUMBER_TYPE,
                    "Default" : 1
                },
                {
                    "Names" : "MaxAdjustment",
                    "Description" : "The maximum instances to  update during scaling activities",
                    "Types" : NUMBER_TYPE,
                    "Default" : 10000
                },
                {
                    "Names" : "TargetCapacity",
                    "Description" : "The target usage of the autoscale group to maintain as a percentage",
                    "Types" : NUMBER_TYPE,
                    "Default" : 90
                },
                {
                    "Names" : "ManageTermination",
                    "Description" : "Alow the computer provider to manage when instances will be terminated",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        }
    ]
/]

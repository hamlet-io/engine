[#ftl]

[@addAttributeSet
    type=AUTOSCALEGROUP_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Control how a virtual machine based autoscaling group behaves"
        }]
    attributes=[
    {
        "Names" : "DetailedMetrics",
        "Types" : BOOLEAN_TYPE,
        "Default" : true,
        "Description" : "Enable the collection of autoscale group detailed metrics"
    },
    {
        "Names" : "MinUpdateInstances",
        "Types" : NUMBER_TYPE,
        "Default" : 1,
        "Description" : "The minimum number of instances which must be available during an update"
    },
    {
        "Names" : "MinSuccessInstances",
        "Types" : NUMBER_TYPE,
        "Description" : "The minimum percantage of instances that must sucessfully update",
        "Default" : 75
    },
    {
        "Names" : "ReplaceCluster",
        "Types" : BOOLEAN_TYPE,
        "Default" : false,
        "Description" : "When set to true a brand new cluster will be built, if false the instances in the current cluster will be replaced"
    },
    {
        "Names" : "UpdatePauseTime",
        "Types" : STRING_TYPE,
        "Default" : "10M",
        "Description" : "How long to pause betweeen updates of instances"
    },
    {
        "Names" : "StartupTimeout",
        "Types" : STRING_TYPE,
        "Default" : "15M",
        "Description" : "How long to wait for a cfn-signal to be received from a host"
    },
    {
        "Names" : "AlwaysReplaceOnUpdate",
        "Types" : BOOLEAN_TYPE,
        "Default" : false,
        "Description" : "Replace instances on every update action"
    },
    {
        "Names" : "ActivityCooldown",
        "Types" : NUMBER_TYPE,
        "Default" : 30
    }
     ]
/]

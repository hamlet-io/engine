[#ftl]

[@addAttributeSet
    type=CONTAINER_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Describes each container that will be used as part of a service or task"
        }
    ]
    attributes=[
        {
            "Names" : [ "Extensions", "Fragment", "Container" ],
            "Description" : "Extensions to invoke as part of component processing",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "Cpu",
            "Description" : "The CPU share to assign to the container",
            "Types" : NUMBER_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Gpu",
            "Description" : "The number of physical GPUs to assign to the container",
            "Types" : NUMBER_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Links",
            "SubObjects": true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "LocalLogging",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "LogDriver",
            "Types" : STRING_TYPE,
            "Values" : ["awslogs", "json-file", "fluentd"],
            "Default" : "awslogs"
        },
        {
            "Names" : "LogMetrics",
            "SubObjects" : true,
            "AttributeSet" : LOGMETRIC_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Alerts",
            "SubObjects" : true,
            "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "ContainerLogGroup",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "RunCapabilities",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "Essential",
            "Description" : "If the container exits the task/service stops all containers and restarts",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Privileged",
            "Description": "Enable privileged host mode for the container",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : ["MaximumMemory", "MemoryMaximum", "MaxMemory"],
            "Description" : "A hard limit of memory available to the container - Set to 0 to not set a maximum",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : ["MemoryReservation", "Memory", "ReservedMemory"],
            "Description" : "A fixed allocation that is assigned to to this container",
            "Types" : NUMBER_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Ports",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names": "Container",
                    "Types": STRING_TYPE
                },
                {
                    "Names" : "DynamicHostPort",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "LB",
                    "AttributeSet" : LBATTACH_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "Registry",
                    "AttributeSet" : SRVREGATTACH_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "IPAddressGroups",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : "Image",
            "Description" : "Set the source of the components image",
            "AttributeSet" : IMAGE_CONTAINER_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Version",
            "Types" : STRING_TYPE,
            "Description" : "Override the version from the deployment unit",
            "Default" : ""
        },
        {
            "Names" : "ContainerNetworkLinks",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "DependsOn",
            "Description": "Defines dependencies between containers in the same task - this container won't start unless these dependencies are met",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "ContainerName",
                    "Description" : "The name of the container to depend on uses the key of this object if not present",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Condition",
                    "Description" : "The required state of the container to start this one",
                    "Values" : [
                        "START",
                        "COMPLETE",
                        "SUCCESS",
                        "HEALTHY"
                    ],
                    "Default" : "START"
                }
            ]
        },
        {
            "Names" : "Profiles",
            "Children" :
                [
                    {
                        "Names" : "Alert",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
        },
        {
            "Names": "ReadonlyRootFilesystem",
            "Descriptions": "Makes the root of the filesystem read-only",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "RunMode",
            "Description" : "A per container setting which can be used by the app to determine run mode for a container in a task - defaults to the second half of a dash separated id",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Ulimits",
            "Description" : "Linux OS based limits for the container",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Name",
                    "Description" : "The name of the ulimit to apply",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "HardLimit",
                    "Description" : "The OS level hard limit to apply",
                    "Types" : NUMBER_TYPE,
                    "Default" : 1024
                },
                {
                    "Names" : "SoftLimit",
                    "Description" : "The User level limit to apply",
                    "Types" : NUMBER_TYPE,
                    "Default" : 1024
                }
            ]
        },
        {
            "Names" : "InitProcess",
            "Description" : "Enable a docker based init process to manage processes",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        }
    ]
/]

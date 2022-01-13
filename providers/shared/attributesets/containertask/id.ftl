[#ftl]

[@addAttributeSet
    type=CONTTAINERTASK_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Descirbes each container that will be used as part of a service or task"
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
            "Children" : logMetricChildrenConfiguration
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
            "Names" : "Privileged",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : ["MaximumMemory", "MemoryMaximum", "MaxMemory"],
            "Types" : NUMBER_TYPE,
            "Description" : "Set to 0 to not set a maximum"
        },
        {
            "Names" : ["MemoryReservation", "Memory", "ReservedMemory"],
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
                    "Children" : lbChildConfiguration
                },
                {
                    "Names" : "Registry",
                    "Children" : srvRegChildConfiguration
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
            "Children" : [
                {
                    "Names" : "Source",
                    "Description" : "The source of the image",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true,
                    "Values" : [ "registry", "containerregistry" ],
                    "Default" : "Registry"
                },
                {
                    "Names" : "Source:containerregistry",
                    "Description" : "A docker container registry to source the image from",
                    "Children" : [
                        {
                            "Names" : "Image",
                            "Description" : "The docker image that you want to use",
                            "Types" : STRING_TYPE
                        }
                    ]
                }
            ]
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
        }
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

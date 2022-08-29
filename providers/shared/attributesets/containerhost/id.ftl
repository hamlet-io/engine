[#ftl]

[@addAttributeSet
    type=CONTAINERHOST_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Describes the configuration required for a container host"
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
            "Names" : [ "MultiAZ", "MultiZone"],
            "Description" : "Deploy resources to multiple Availablity Zones",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "FixedIP",
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
            "Names" : "VolumeDrivers",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Values" : [ "ebs" ],
            "Default" : []
        },
        {
            "Names" : "ClusterLogGroup",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Links",
            "SubObjects": true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Profiles",
            "Children" :
                [
                    {
                        "Names" : "ComputeProvider",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Processor",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Storage",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Alert",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Network",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Logging",
                        "Description" : "profile to define where logs are forwarded to from this component",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "LogFile",
                        "Description" : "Defines the logfile profile which sets the log files to collect from the compute instance",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Bootstrap",
                        "Description" : "A profile to include additional bootstrap sources as part of the instance startup",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
        },
        {
            "Names" : "Permissions",
            "Children" : [
                {
                    "Names" : "Decrypt",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "AsFile",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "AppData",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "AppPublic",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        },
        {
            "Names" : "AutoScaling",
            "AttributeSet" : AUTOSCALEGROUP_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "HostScalingPolicies",
            "SubObjects" : true,
            "AttributeSet" : SCALINGPOLICY_ECS_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "DockerUsers",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "UserName",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "UID",
                    "Types" : NUMBER_TYPE,
                    "Mandatory" : true
                }
            ]
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
            "Names" : "Hibernate",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "StartUpMode",
                    "Types" : STRING_TYPE,
                    "Values" : ["replace"],
                    "Default" : "replace"
                }
            ]
        },
        {
            "Names" : "Role",
            "Types" : STRING_TYPE,
            "Description" : "Server configuration role",
            "Default" : ""
        },
        {
            "Names" : "ComputeInstance",
            "Description" : "Configuration of compute instances used in the component",
            "Children" : [
                {
                    "Names" : "ManagementPorts",
                    "Description" : "The network ports used for remote management of the instance",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : [ "ssh" ]
                },
                {
                    "Names" : "Image",
                    "Description" : "Configures the source of the virtual machine image used for the instance",
                    "AttributeSet" : ECS_COMPUTEIMAGE_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "OperatingSystem",
                    "Description" : "The operating system details of the compute instance",
                    "AttributeSet" : OPERATINGSYSTEM_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "OSPatching",
                    "Description" : "Configuration for scheduled OS Patching",
                    "AttributeSet" : OSPATCHING_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "AntiVirus",
                    "AttributeSet" : ANTIVIRUS_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "ComputeTasks",
                    "Description" : "Customisation to setup the compute instance from its image",
                    "Children" : [
                        {
                            "Names" : "Extensions",
                            "Description" : "A list of extensions to source boostrap tasks from",
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
                        },
                        {
                            "Names" : "UserTasksRequired",
                            "Description" : "A list of compute task types which must be accounted for in extensions on top of the component tasks",
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
                        }
                    ]
                }
            ]
        }
    ]
/]

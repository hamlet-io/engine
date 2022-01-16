[#ftl]

[@addComponent
    type=EC2_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A single virtual machine with no code deployment "
            }
        ]
    attributes=
        [
            {
                "Names" : "FixedIP",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "DockerHost",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
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
                "Names" : "Ports",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "IPAddressGroups",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "LB",
                        "AttributeSet" : LBATTACH_ATTRIBUTESET_TYPE
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
                "Names" : "StartupTimeout",
                "Types" : NUMBER_TYPE,
                "Description" : "The time in seconds to wait for startup configuration to complete",
                "Default" : 300
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
                        "AttributeSet" : COMPUTEIMAGE_ATTRIBUTESET_TYPE
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

[@addComponentDeployment
    type=EC2_COMPONENT_TYPE
    defaultGroup="solution"
/]

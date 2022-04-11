[#ftl]

[@addComponent
    type=COMPUTECLUSTER_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Auto-Scaling IaaS with code deployment"
            }
        ]
    attributes=
        [
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
                "Names" : [ "MultiAZ", "MultiZone"],
                "Description" : "Deploy resources to multiple Availablity Zones",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AutoScaling",
                "AttributeSet" : AUTOSCALEGROUP_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "ScalingPolicies",
                "SubObjects" : true,
                "AttributeSet" : SCALINGPOLICY_ATTRIBUTESET_TYPE
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
                "Names" : "Image",
                "Description" : "Control the source of the image that is used for the computecluster",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The source of the image - registry is the hamlet registry",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true,
                        "Values" : [ "registry", "url", "none" ],
                        "Default" : "registry"
                    },
                    {
                        "Names" : "Source:url",
                        "Description" : "Url Source specific Configuration",
                        "Children" : [
                            {
                                "Names" : "Url",
                                "Description" : "The url to a source zip file",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "ImageHash",
                                "Description" : "The expected sha1 hash of the Url if empty any will be accepted",
                                "Types" : STRING_TYPE,
                                "Default" : ""
                            }
                        ]
                    }
                ]
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
    type=COMPUTECLUSTER_COMPONENT_TYPE
    defaultGroup="application"
/]

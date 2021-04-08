[#ftl]

[@addComponentDeployment
    type=BASTION_COMPONENT_TYPE
    defaultGroup="segment"
/]

[@addComponent
    type=BASTION_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "An bastion instance to manage vpc only components"
            }
        ]
    attributes=
        [
            {
                "Names" : "Active",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "OS",
                "Types" : STRING_TYPE,
                "Values" : ["linux"],
                "Default" : "linux"
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
                "Names" : "IPAddressGroups",
                "Description" : "The IPAddressGroup Id's that should be granted access to the Bastion",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
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
                            "Names" : "Network",
                            "Types":  STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "AutoScaling",
                "Children" : autoScalingChildConfiguration
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
                "Names" : "Role",
                "Types" : STRING_TYPE,
                "Description" : "Server configuration role",
                "Default" : ""
            },
            {
                "Names" : "OSPatching",
                "Children" : osPatchingChildConfiguration
            },
            {
                "Names" : "Image",
                "Description" : "Configures the source of the virtual machine image used for the instance",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "Where to source the image id from - Reference: uses the Regions AMIs reference property to find the image",
                        "Values" : [ "Reference" ]
                    },
                    {
                        "Names" : "Reference",
                        "Children" : [
                            {
                                "Names" : "OS",
                                "Description" : "The OS Image family defined in the Region AMI",
                                "Default" : "Centos"
                            },
                            {
                                "Names" : "Type",
                                "Description" : "The image Type defined under the family in the Region AMI",
                                "Default" : "EC2"
                            }
                        ]
                    }
                ]
            }
        ]
/]

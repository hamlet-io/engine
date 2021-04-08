[#ftl]

[@addComponentDeployment
    type=COMPUTECLUSTER_COMPONENT_TYPE
    defaultGroup="application"
/]

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
                            "Names" : "Network",
                            "Types" : STRING_TYPE,
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
                "Names" : "UseInitAsService",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AutoScaling",
                "Children" : autoScalingChildConfiguration
            },
            {
                "Names" : "ScalingPolicies",
                "SubObjects" : true,
                "Children" : scalingPolicyChildrenConfiguration
            },
            {
                "Names" : "DockerHost",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
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
                        "Children" : lbChildConfiguration
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

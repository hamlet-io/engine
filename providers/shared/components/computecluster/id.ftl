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
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "attributeset",
                    "Type" : LINK_ATTRIBUTESET_TYPE
                }
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
                "Subobjects" : true,
                "Children" : scalingPolicyChildrenConfiguration
            },
            {
                "Names" : "DockerHost",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Ports",
                "Subobjects" : true,
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
            }
        ]
/]

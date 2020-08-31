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
                "Names" : "DeploymentGroup",
                "Type" : STRING_TYPE,
                "Default" : "solution"
            },
            {
                "Names" : "FixedIP",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "DockerHost",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : ["Fragment", "Container"],
                "Type" : "string",
                "Default" : ""
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Processor",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Ports",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "IPAddressGroups",
                        "Type" : ARRAY_OF_STRING_TYPE,
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
                "Description" : "Server configuration role",
                "Default" : ""
            }
        ]
/]

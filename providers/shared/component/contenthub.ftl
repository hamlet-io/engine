[#ftl]

[#assign componentConfiguration +=
    {
        CONTENTHUB_HUB_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "Hub for decentralised content hosting with centralised publishing"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "github" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Prefix",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
                    "Default" : "github"
                },
                {
                    "Names" : "Branch",
                    "Type" : STRING_TYPE,
                    "Default" : "master"
                },
                {
                    "Names" : "Repository",
                    "Type" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        CONTENTHUB_NODE_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "Node for decentralised content hosting with centralised publishing"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "github" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Path",
                    "Children" : pathChildConfiguration
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                }
            ]
        }
    }]

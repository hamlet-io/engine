[#-- CONTENTHUB --]

[#-- Resources --]
[#assign COT_CONTENTHUB_HUB_RESOURCE_TYPE = "contenthub"]
[#assign COT_CONTENTHUB_NODE_RESOURCE_TYPE = "contentnode"]

[#-- Components --]
[#assign CONTENTHUB_HUB_COMPONENT_TYPE = "contenthub"]

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
        }
    }]

[#function getContentHubState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(COT_CONTENTHUB_HUB_RESOURCE_TYPE, core.Id)]

    [#return
        {
            "Resources" : {
                "contenthub" : {
                    "Id" : id,
                    "Type" : COT_CONTENTHUB_HUB_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "ENGINE" : solution.Engine,
                "REPOSITORY" : solution.Repository,
                "BRANCH" : solution.Branch,
                "PREFIX" : solution.Prefix
            }
        }
    ]
[/#function]


[#assign CONTENTHUB_NODE_COMPONENT_TYPE = "contentnode"]

[#assign componentConfiguration +=
    {
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
                    "Children" : [
                        {
                            "Names" : "Host",
                            "Type" : STRING_TYPE,
                            "Default" : ""
                        },
                        {
                            "Names" : "Style",
                            "Type" : STRING_TYPE,
                            "Default" : "single"
                        },
                        {
                            "Names" : "IncludeInPath",
                            "Children" : [

                                {
                                    "Names" : "Product",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Environment",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : false
                                },
                                {
                                    "Names" : "Solution",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : false
                                },
                                {
                                    "Names" : "Segment",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Tier",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default": false
                                },
                                {
                                    "Names" : "Component",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : false
                                },
                                {
                                    "Names" : "Instance",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : false
                                },
                                {
                                    "Names" : "Version",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default" : false
                                },
                                {
                                    "Names" : "Host",
                                    "Type" : BOOLEAN_TYPE,
                                    "Default": false
                                }
                            ]
                        }
                    ]
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                }
            ]
        }
    }]

[#function getContentNodeState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(COT_CONTENTHUB_NODE_RESOURCE_TYPE, core.Id)]

    [#return
        {
            "Resources" : {
                "contentnode" : {
                    "Id" : id,
                    "Type" : COT_CONTENTHUB_NODE_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "PATH" : getContentPath(occurrence)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

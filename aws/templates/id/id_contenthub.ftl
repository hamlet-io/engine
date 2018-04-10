[#-- CONTENTHUB --]

[#-- Resources --]
[#assign COT_CONTENTHUB_HUB_RESOURCE_TYPE = "contenthub"]
[#assign COT_CONTENTHUB_NODE_RESOURCE_TYPE = "contentnode"]

[#-- Components --]
[#assign CONTENTHUB_HUB_COMPONENT_TYPE = "contenthub"]

[#assign componentConfiguration +=
    {
        CONTENTHUB_HUB_COMPONENT_TYPE : [
            "Prefix",
            {
                "Name" : "Engine",
                "Default" : "github"
            },
            {
                "Name" : "Branch",
                "Default" : "master"
            },
            {
                "Name" : "Repository",
                "Default" : ""
            }
        ]
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
        CONTENTHUB_NODE_COMPONENT_TYPE : [
            {
                "Name" : "Path",
                "Children" : [
                    {
                        "Name" : "Host",
                        "Default" : ""
                    },
                    {
                        "Name" : "Style",
                        "Default" : "single"
                    },
                    {
                        "Name" : "IncludeInPath",
                        "Children" : [

                            {
                                "Name" : "Product",
                                "Default" : true
                            },
                            {
                                "Name" : "Environment",
                                "Default" : false
                            },
                            {
                                "Name" : "Solution",
                                "Default" : false
                            },
                            {
                                "Name" : "Segment",
                                "Default" : true
                            },
                            {
                                "Name" : "Tier",
                                "Default": false
                            },
                            {
                                "Name" : "Component",
                                "Default" : false
                            },
                            {
                                "Name" : "Instance",
                                "Default" : false
                            },
                            {
                                "Name" : "Version",
                                "Default" : false
                            },
                            {
                                "Name" : "Host",
                                "Default": false
                            }
                        ]
                    }
                ]
            },
            {
                "Name" : "Links",
                "Default" : {}
            }
        ]
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

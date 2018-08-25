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
                "Type" : "string",
                "Default" : "github"
            },
            {
                "Name" : "Branch",
                "Type" : "string",
                "Default" : "master"
            },
            {
                "Name" : "Repository",
                "Type" : "string",
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
                        "Type" : "string",
                        "Default" : ""
                    },
                    {
                        "Name" : "Style",
                        "Type" : "string",
                        "Default" : "single"
                    },
                    {
                        "Name" : "IncludeInPath",
                        "Children" : [

                            {
                                "Name" : "Product",
                                "Type" : "boolean",
                                "Default" : true
                            },
                            {
                                "Name" : "Environment",
                                "Type" : "boolean",
                                "Default" : false
                            },
                            {
                                "Name" : "Solution",
                                "Type" : "boolean",
                                "Default" : false
                            },
                            {
                                "Name" : "Segment",
                                "Type" : "boolean",
                                "Default" : true
                            },
                            {
                                "Name" : "Tier",
                                "Type" : "boolean",
                                "Default": false
                            },
                            {
                                "Name" : "Component",
                                "Type" : "boolean",
                                "Default" : false
                            },
                            {
                                "Name" : "Instance",
                                "Type" : "boolean",
                                "Default" : false
                            },
                            {
                                "Name" : "Version",
                                "Type" : "boolean",
                                "Default" : false
                            },
                            {
                                "Name" : "Host",
                                "Type" : "boolean",
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

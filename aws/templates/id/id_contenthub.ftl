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
                "Type" : STRING_TYPE,
                "Default" : "github"
            },
            {
                "Name" : "Branch",
                "Type" : STRING_TYPE,
                "Default" : "master"
            },
            {
                "Name" : "Repository",
                "Type" : STRING_TYPE,
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
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Name" : "Style",
                        "Type" : STRING_TYPE,
                        "Default" : "single"
                    },
                    {
                        "Name" : "IncludeInPath",
                        "Children" : [

                            {
                                "Name" : "Product",
                                "Type" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Name" : "Environment",
                                "Type" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Name" : "Solution",
                                "Type" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Name" : "Segment",
                                "Type" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Name" : "Tier",
                                "Type" : BOOLEAN_TYPE,
                                "Default": false
                            },
                            {
                                "Name" : "Component",
                                "Type" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Name" : "Instance",
                                "Type" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Name" : "Version",
                                "Type" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Name" : "Host",
                                "Type" : BOOLEAN_TYPE,
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

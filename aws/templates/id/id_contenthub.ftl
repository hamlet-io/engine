[#-- CONTENTHUB --]
[#assign CONTENTHUB_HUB_COMPONENT_TYPE = "contenthub"]
[#assign CONTENTHUB_NODE_COMPONENT_TYPE = "contentnode"]

[#assign CONTENTHUB_RESOURCE_TYPE = "contenthub"]
[#assign CONTENTNODE_RESOURCE_TYPE = "contentnode"]

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
    [#local configuration = occurrence.Configuration]

    [#local id = formatResourceId(CONTENTHUB_RESOURCE_TYPE, core.Id)]

    [#return
        {
            "Resources" : {
                "contenthub" : {
                    "Id" : id
                }
            },
            "Attributes" : {
                "ENGINE" : getExistingReference(id, ENGINE_ATTRIBUTE_TYPE),
                "REPOSITORY" : getExistingReference(id, REPOSITORY_ATTRIBUTE_TYPE),
                "BRANCH" : getExistingReference(id, BRANCH_ATTRIBUTE_TYPE),
                "PREFIX" : getExistingReference(id, PREFIX_ATTRIBUTE_TYPE)
            }
        }
    ]
[/#function]

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
            }
            {
                "Name" : "Links",
                "Default" : {}
            }
        ]
    }]

[#function getContentNodeState occurrence]
    [#local core = occurrence.Core]
    [#local configuration = occurrence.Configuration]

    [#local id = formatResourceId(CONTENTNODE_RESOURCE_TYPE, core.Id)]

    [#return
        {
            "Resources" : {
                "contentnode" : {
                    "Id" : id
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

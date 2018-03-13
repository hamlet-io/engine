[#-- CONTENTHUB --]

[#assign CONTENTHUB_HUB_RESOURCE_TYPE = "contenthub" ]
[#assign CONTENTHUB_NODE_RESOURCE_TYPE = "contentnode" ]

[#function formatContentHubHubId tier component extensions...]
    [#return formatComponentResourceId(
                CONTENTHUB_HUB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]


[#function formatContentHubNodeId tier component extensions...]
    [#return formatComponentResourceId(
                CONTENTHUB_NODE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]


[#assign componentConfiguration +=
    {
        "contenthub" : [
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

    [#local id = formatContentHubHubId(core.Tier, core.Component, occurrence)]

    [#return
        {
            "Resources" : {
                "hub" : {
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
        "contentnode" : [
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

    [#local id = formatContentHubNodeId(core.Tier, core.Component, occurrence)]

    [#return
        {
            "Resources" : {
                "node" : {
                    "Id" : id
                }
            },
            "Attributes" : {
                "PATH" : getContentPath(occurrence)
            }
        }
    ]
[/#function]

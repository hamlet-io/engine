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

[#macro aws_contenthub_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getContentHubState(occurrence, baseState)]
[/#macro]

[#function getContentHubState occurrence baseState]
    [#local core = occurrence.Core]

    [#if core.External!false ]
        [#local engine = (baseState.Attributes["ENGINE"])!"COTException: Engine not found" ]
        [#local repoistory = (baseState.Attributes["REPOSITORY"])!"COTException: Repository not found" ]
        [#local branch = (baseState.Attributes["BRANCH"])!"COTException: Bracnch not found" ]
        [#local prefix = (baseState.Attributes["PREFIX"])!"COTException: Prefix not found" ]

        [#return
            baseState +
            {
                "Attributes" : {
                    "ENGINE" : engine,
                    "REPOSITORY" : repoistory,
                    "BRANCH" : branch,
                    "PREFIX" : prefix
                }
            }
        ]
    [#else]
        [#local solution = occurrence.Configuration.Solution]
        [#local id = formatResourceId(COT_CONTENTHUB_HUB_RESOURCE_TYPE, core.Id)]

        [#local engine = solution.Engine ]
        [#local repoistory = solution.Repository ]
        [#local branch = solution.Branch ]
        [#local prefix = solution.Prefix ]

        [#return
            {
                "Resources" : {
                    "contenthub" : {
                        "Id" : id,
                        "Type" : COT_CONTENTHUB_HUB_RESOURCE_TYPE,
                        "Deployed" : true
                    }
                },
                "Attributes" : {
                    "ENGINE" : engine,
                    "REPOSITORY" : repoistory,
                    "BRANCH" : branch,
                    "PREFIX" : prefix
                },
                "Roles" : {
                    "Inbound" : {},
                    "Outbound" : {}
                }
            }
        ]
    [/#if]
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

[#macro aws_contentnode_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getContentNodeState(occurrence)]
[/#macro]

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

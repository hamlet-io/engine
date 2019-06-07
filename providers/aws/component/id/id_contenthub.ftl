[#-- Resources --]
[#assign COT_CONTENTHUB_HUB_RESOURCE_TYPE = "contenthub"]
[#assign COT_CONTENTHUB_NODE_RESOURCE_TYPE = "contentnode"]

[#macro aws_contenthub_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]

    [#if core.External!false ]
        [#local engine = (baseState.Attributes["ENGINE"])!"COTException: Engine not found" ]
        [#local repoistory = (baseState.Attributes["REPOSITORY"])!"COTException: Repository not found" ]
        [#local branch = (baseState.Attributes["BRANCH"])!"COTException: Bracnch not found" ]
        [#local prefix = (baseState.Attributes["PREFIX"])!"COTException: Prefix not found" ]

        [#assign componentState =
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

        [#assign componentState =
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
[/#macro]

[#macro aws_contentnode_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(COT_CONTENTHUB_NODE_RESOURCE_TYPE, core.Id)]

    [#assign componentState =
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
[/#macro]

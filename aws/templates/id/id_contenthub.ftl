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
                "Default" : "git"
            },
            {
                "Name" : "Branch",
                "Default" : "master"
            },
            {
                "Name" : "URL",
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
                "primary" : {
                    "Id" : id
                }
            },
            "Attributes" : {
                "ENGINE" : getExistingReference(id, ENGINE_ATTRIBUTE_TYPE),
                "URL"    : getExistingReference(id, URL_ATTRIBUTE_TYPE),
                "BRANCH" : getExistingReference(id, BRANCH_ATTRIBUTE_TYPE),
                "PREFIX" : getExistingReference(id, PREFIX_ATTRIBUTE_TYPE)
            }
        }
    ]
[/#function]


[#assign componentConfiguration +=
    {
        "contentnode" : [
            "Path",
            {
                "Name" : "Links",
                "Default" : {}
            }
        ]
    }]

    
[#function getContentNodeState occurrence]
    [#local core = occurrence.Core]
    [#local configuration = occurrence.Configuration]

    [#local id = formatContentHubHubId(core.Tier, core.Component, occurrence)]

    [#return
        {
            "Resources" : {
                "primary" : {
                    "Id" : id
                }
            },
            "Attributes" : {
                "PATH" : configuration.Path
            }
        }
    ]
[/#function]

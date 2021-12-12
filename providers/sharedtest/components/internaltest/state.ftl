[#ftl]

[#macro sharedtest_internaltest_default_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local attributes = {}]
    [#local contextLinks = getLinkTargets(occurrence) ]
    [#local _context =
        {
            "DefaultEnvironment" : defaultEnvironment(occurrence, {}, {}),
            "Environment" : {},
            "Links" : contextLinks,
            "BaselineLinks" : {},
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : true,
            "DefaultBaselineVariables" : false,
            "DefaultLinkVariables" : false
        }
    ]

    [#-- Add in extension specifics including override of defaults --]
    [#local _context = invokeExtensions( occurrence, _context, {}, solution.Extensions, true )]

    [#local environment = getFinalEnvironment(occurrence, _context ).Environment ]

    [#list environment as name,value]
        [#local attributes += { name : value } ]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "external" : {
                    "Id" : formatResourceId("internaltest", core.Id),
                    "Type" : "internaltest",
                    "Deployed" : true
                }
            },
            "Attributes" : attributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

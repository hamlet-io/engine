[#ftl]

[@addExtension
    id="contextpath_content"
    aliases=[
        "_contextpath_content"
    ]
    description=[
        "Testing for contextpath attributeset and builder function"
    ]
    supportedTypes=[
        INTERNALTEST_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_contextpath_content_deployment_setup occurrence ]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]

    [#-- All defaults to creat the path --]
    [#local defaultPath =
        getCompositeObject(
            {
                "Names" : "Path",
                "AttributeSet" : CONTEXTPATH_ATTRIBUTESET_TYPE
            },
            {
            }
        )]

    [@Settings
        {
            "DEFAULT_CONTEXTPATH_OUTPUT" : getContextPath(occurrence, defaultPath["Path"] )
        }
    /]


    [#-- All Possible Includes --]
    [#local defaultPath =
        getCompositeObject(
            {
                "Names" : "Path",
                "AttributeSet" : CONTEXTPATH_ATTRIBUTESET_TYPE
            },
            {
                "Path" : {
                    "Custom" : "allincludes",
                    "IncludeInPath" : {
                        "Account" : true,
                        "ProviderId" : true,
                        "Product" : true,
                        "Environment" : true,
                        "Segment" : true,
                        "Tier" : true,
                        "Component" : true,
                        "Instance" : true,
                        "Version" : true,
                        "Custom" : true
                    }
                }
            }
        )]

    [@Settings
        {
            "ALLINCLUDES_CONTEXTPATH_OUTPUT" : getContextPath(occurrence, defaultPath["Path"] )
        }
    /]

[/#macro]

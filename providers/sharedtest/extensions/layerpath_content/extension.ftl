[#ftl]

[@addExtension
    id="layerpath_content"
    aliases=[
        "_layerpath_content"
    ]
    description=[
        "Testing for layer path attribute setup and output"
    ]
    supportedTypes=[
        INTERNALTEST_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_layerpath_content_deployment_setup occurrence ]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]

    [#-- All defaults to creat the path --]
    [#local defaultPath =
        getCompositeObject(
            {
                "Names" : "Path",
                "AttributeSet" : LAYERPATH_ATTRIBUTESET_TYPE
            },
            {
            }
        )]

    [@Settings
        {
            "DEFAULT_LAYERPATH_OUTPUT" : getLayerPath(occurrence, defaultPath["Path"] )
        }
    /]


    [#-- All Possible Includes --]
    [#local defaultPath =
        getCompositeObject(
            {
                "Names" : "Path",
                "AttributeSet" : LAYERPATH_ATTRIBUTESET_TYPE
            },
            {
                "Path" : {
                    "Custom" : "allincludes",
                    "IncludeInPath" : {
                        "Account" : true,
                        "ProviderId" : true,
                        "Product" : true,
                        "Environment" : true,
                        "Solution" : true,
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
            "ALLINCLUDES_LAYERPATH_OUTPUT" : getLayerPath(occurrence, defaultPath["Path"] )
        }
    /]

[/#macro]

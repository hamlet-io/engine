[#ftl]

[#macro shared_input_shared_commandlineoption_seed ]
    [#-- Entrance --]
    [@addCommandLineOption
        option={
            "Entrance" : {
                "Type" : entrance!"deployment"
            }
        }
    /]

    [#-- Flows --]
    [@addCommandLineOption
        option={
            "Flow" : {
                "Names" : asArray( flows?split(",") )![]
            }
        }
    /]

    [#-- Input data control --]
    [@addCommandLineOption
        option={
            "Input" : {
                "Source" : inputSource!"composite"
            }
        }
    /]

    [#-- load the plugin state from setup --]
    [@addCommandLineOption
        option={
            "Plugins" : {
                "State" : (pluginState!"")?has_content?then(
                                pluginState?eval,
                                {}
                )
            }
        }
    /]

    [#-- Deployment Details --]
    [@addCommandLineOption
        option={
            "Deployment" : {
                "Provider" : {
                    "Names" : (providers!"")?has_content?then(
                                    providers?split(","),
                                    []
                    )
                },
                "Framework" : {
                    "Name" : deploymentFramework!"default"
                },
                "Output" : {
                    "Type" : outputType!"",
                    "Format" : outputFormat!"",
                    "Prefix" : outputPrefix!""
                },
                "Group" : {
                    "Name" : deploymentGroup!""
                },
                "Unit" : {
                    "Name" : deploymentUnit!"",
                    "Subset" : deploymentUnitSubset!"",
                    "Alternative" : alternative!""
                },
                "ResourceGroup" : {
                    "Name" : resourceGroup!""
                },
                "Mode" : deploymentMode!""
            }
        }
    /]

    [#-- Layer Details --]
    [@addCommandLineOption
        option={
            "Layers" : {
                "Tenant" : tenant!"",
                "Account" : account!"",
                "Product" : product!"",
                "Environment" : environment!"",
                "Segment" : segment!""
            }
        }
    /]

    [#-- Logging Details --]
    [@addCommandLineOption
        option={
            "Logging" : {
                "Level" : logLevel!""
            }
        }
    /]

    [#-- RunId details --]
    [@addCommandLineOption
        option={
            "Run" : {
                "Id" : runId!""
            }
        }
    /]

[/#macro]

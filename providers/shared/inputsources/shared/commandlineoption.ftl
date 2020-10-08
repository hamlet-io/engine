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

    [#-- Deployment Details --]
    [@addCommandLineOption
        option={
            "Deployment" : {
                "Provider" : {
                    "Names" : asArray( providers?split(",") )![]
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

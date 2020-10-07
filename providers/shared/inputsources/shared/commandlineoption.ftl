[#ftl]

[#macro shared_input_shared_commandlineoption_seed ]
    [#-- Document Set --]
    [@addCommandLineOption
        option={
            "Entrance" : {
                "Type" : entrance!"deployment"
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
                    "Name" : deploymentFramework!"",
                    "Model" : deploymentFrameworkModel!"legacy",
                    "Flow" : deploymentFrameworkScope!COMPONENTS_MODEL_FLOW
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

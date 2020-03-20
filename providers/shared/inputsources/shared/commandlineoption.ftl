[#ftl]

[#macro shared_input_shared_commandlineoption_seed ]

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
                    "Model" : deploymentFrameworkModel!"legacy"
                },
                "Output" : {
                    "Type" : outputType!"",
                    "Format" : outputFormat!"",
                    "Prefix" : outputPrefix!""
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

    [@pushInputsPlacementContext
        {
            "Account" : account!"",
            "Region" : region!""
        }
    /]

    [@pushInputsProductContext
        {
            "Tenant" : tenant!"",
            "Product" : product!"",
            "Environment" : environment!"",
            "Segment" : segment!""
        }
    /]
[/#macro]

[#ftl]
[#-- Command line options control how the engine behaves --]

[#assign commandLineOptions = {} ]

[#macro addCommandLineOption option={} ]
    [#if option?has_content ]
        [@internalMergeCommandLineOption
            option=option
        /]
    [/#if]
[/#macro]

[#-- Command line options used across a lot of different places --]
[#macro setDeploymentUnit deploymentUnit ]
    [@addCommandLineOption
        option={
            "Deployment" : {
                "Unit" : {
                    "Name" : deploymentUnit
                }
            }
        }
    /]
[/#macro]

[#function getDeploymentUnit ]
    [#return (commandLineOptions["Deployment"]["Unit"]["Name"])!"" ]
[/#function]

[#function getDeploymentGroup ]
    [#return (commandLineOptions["Deployment"]["Group"]["Name"])!"" ]
[/#function]
[#-----------------------------------------------------
-- Internal support functions for blueprint processing --
-------------------------------------------------------]

[#macro internalMergeCommandLineOption option ]
    [#assign commandLineOptions = mergeObjects(
                                    commandLineOptions,
                                    option
    )]
[/#macro]

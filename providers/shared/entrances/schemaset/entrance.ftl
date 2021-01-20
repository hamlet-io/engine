[#ftl]

[#macro shared_entrance_schemaset ]

    [@addCommandLineOption
        option={
            "Deployment" : {
                "Framework" : {
                    "Name" : DEFAULT_DEPLOYMENT_FRAMEWORK
                }
            },
            "View" : {
                "Name" : SCHEMASET_VIEW_TYPE
            },
            "Flow" : {
                "Names" : [ "views" ]
            }
        }
    /]

    [@generateOutput
        deploymentFramework=commandLineOptions.Deployment.Framework.Name
        type=commandLineOptions.Deployment.Output.Type
        format=commandLineOptions.Deployment.Output.Format
    /]

[/#macro]
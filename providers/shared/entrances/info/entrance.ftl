[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_info ]

  [@generateOutput
    deploymentFramework=getCLODeploymentFramework()
    type=getCLODeploymentOutputType()
    format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_info_inputsteps ]

    [@registerInputSeeder
        id=INFO_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=INFO_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function info_configseeder_commandlineoptions filter state]

    [#return
        addToConfigPipelineClass(
            state,
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            {
                "Deployment" : {
                    "Framework" : {
                        "Name" : DEFAULT_DEPLOYMENT_FRAMEWORK
                    }
                },
                "Flow" : {
                    "Names" : [ "views" ]
                },
                "View" : {
                    "Name" : INFO_VIEW_TYPE
                }
            }
        )
    ]

[/#function]

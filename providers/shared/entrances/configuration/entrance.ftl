[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_configuration ]

  [@generateOutput
    deploymentFramework=getCLODeploymentFramework()
    type=getCLODeploymentOutputType()
    format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_configuration_inputsteps ]

    [@registerInputSeeder
        id=CONFIGURATION_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=CONFIGURATION_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function configuration_configseeder_commandlineoptions filter state]

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
                    "Name" : CONFIGURATION_VIEW_TYPE
                }
            }
        )
    ]

[/#function]

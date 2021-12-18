[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_schemalist ]

    [@generateOutput
      deploymentFramework=getCLODeploymentFramework()
      type=getCLODeploymentOutputType()
      format=getCLODeploymentOutputFormat()
    /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_schemalist_inputsteps ]

    [@registerInputSeeder
        id=SCHEMALIST_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=SCHEMALIST_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function schemalist_configseeder_commandlineoptions filter state]

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
                    "Name" : SCHEMALIST_VIEW_TYPE
                }
            }
        )
    ]

[/#function]

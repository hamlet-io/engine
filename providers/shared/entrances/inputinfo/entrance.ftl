[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_inputinfo ]

  [@generateOutput
    deploymentFramework=getCLODeploymentFramework()
    type=getCLODeploymentOutputType()
    format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_inputinfo_inputsteps ]

    [@registerInputSeeder
        id=INPUTINFO_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=INPUTINFO_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function inputinfo_configseeder_commandlineoptions filter state]

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
                    "Name" : INPUTINFO_VIEW_TYPE
                }
            }
        )
    ]

[/#function]

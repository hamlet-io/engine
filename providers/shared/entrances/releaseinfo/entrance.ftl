[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_releaseinfo ]

  [@generateOutput
    deploymentFramework=getCLODeploymentFramework()
    type=getCLODeploymentOutputType()
    format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_releaseinfo_inputsteps ]

    [@registerInputSeeder
        id=RELEASEINFO_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=RELEASEINFO_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function releaseinfo_configseeder_commandlineoptions filter state]

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
                    "Name" : RELEASEINFO_VIEW_TYPE
                }
            }
        )
    ]

[/#function]

[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_runbook ]
    [@generateOutput
        deploymentFramework=getCLODeploymentFramework()
        type=getCLODeploymentOutputType()
        format=getCLODeploymentOutputFormat()
    /]
[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_runbook_inputsteps ]

    [@registerInputSeeder
        id=RUNBOOK_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=RUNBOOK_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function runbook_configseeder_commandlineoptions filter state]

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
                "RunBook" : RunBook!"",
                "RunBookInputs" : ((RunBookInputs)!"{}")?eval_json
            }
        )
    ]

[/#function]

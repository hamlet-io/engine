[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_stackoutput ]

    [#local deploymentGroupDetails = getDeploymentGroupDetails(getDeploymentGroup())]

    [@generateOutput
        deploymentFramework=getCLODeploymentFramework()
        type=getCLODeploymentOutputType()
        format=getCLODeploymentOutputFormat()
        level=getDeploymentLevel()
        include=(.vars[deploymentGroupDetails.CompositeTemplate])!""
    /]
[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_stackoutput_inputsteps ]

    [@registerInputSeeder
        id=STACKOUTPUT_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=STACKOUTPUT_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function stackoutput_configseeder_commandlineoptions filter state]

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
                "StackOutputContent" : ((StackOutputContent)!"{}")?eval_json
            }
        )
    ]

[/#function]

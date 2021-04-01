[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_validate ]

    [#assign allDeploymentUnits = true]

    [#if getCLODeploymentUnitSubset() == "generationcontract" ]
        [#assign allDeploymentUnits = false]
    [/#if]

  [@generateOutput
    deploymentFramework=getCLODeploymentFramework()
    type=getCLODeploymentOutputType()
    format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_validate_inputsteps ]

    [@registerInputSeeder
        id=VALIDATE_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=VALIDATE_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view and enable validation --]
[#function validate_configseeder_commandlineoptions filter state]

    [#return
        addToConfigPipelineClass(
            state,
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            {
                "Deployment" : {
                    "Unit" : {
                        "Name" : ""
                    },
                    "Group" : {
                        "Name" : "*"
                    },
                        "Framework" : {
                        "Name" : DEFAULT_DEPLOYMENT_FRAMEWORK
                    }
                },
                "Flow" : {
                    "Names" : [ "views" ]
                },
                "View" : {
                    "Name" : VALIDATE_VIEW_TYPE
                },
                "Validate" : true
            }
        )
    ]

[/#function]

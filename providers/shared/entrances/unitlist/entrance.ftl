[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_unitlist ]

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
[#macro shared_entrance_unitlist_inputsteps ]

    [@registerInputSeeder
        id=UNITLIST_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=UNITLIST_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function unitlist_configseeder_commandlineoptions filter state]

    [#return
        addToConfigPipelineClass(
            state,
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            {
                "Deployment" : {
                    "Group" : {
                        "Name" : "*"
                    }
                },
                "Flow" : {
                    "Names" : [ "components", "views"  ]
                },
                "View" : {
                    "Name" : UNITLIST_VIEW_TYPE
                }
            }
        )
    ]

[/#function]

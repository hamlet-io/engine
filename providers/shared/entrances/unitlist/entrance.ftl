[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_unitlist ]

  [#assign allDeploymentUnits = true]

  [#if getDeploymentUnitSubset() == "generationcontract" ]
    [#assign allDeploymentUnits = false]
  [/#if]

  [@generateOutput
    deploymentFramework=getDeploymentFramework()
    type=getDeploymentOutputType()
    format=getDeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_loader_inputsteps ]

    [@registerInputSeeder
        id=UNITLIST_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToInputPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=UNITLIST_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function unitlist_inputseeder_commandlineoptions filter state]

    [#return
        mergeObjects(
            state,
            {
                "CommandLineOptions" : {
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
            }
        )
    ]

[/#function]

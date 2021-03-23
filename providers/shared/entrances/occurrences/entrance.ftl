[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_occurrences ]

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
[#macro shared_entrance_occurrences_inputsteps ]

    [@registerInputSeeder
        id=OCCURRENCES_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=OCCURRENCES_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow --]
[#function occurrences_configseeder_commandlineoptions filter state]

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
                        "Names" : [ "components" ]
                    }
                }
            }
        )
    ]

[/#function]

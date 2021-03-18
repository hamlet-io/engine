[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_occurrences ]

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
[#macro shared_entrance_occurrences_inputsteps ]

    [@registerInputSeeder
        id=OCCURRENCES_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToInputPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=OCCURRENCES_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow --]
[#function occurrences_inputseeder_commandlineoptions filter state]

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

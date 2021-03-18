[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_loader ]

  [@generateOutput
    deploymentFramework=getDeploymentFramework()
    type=getDeploymentOutputType()
    format=getDeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_loader_inputsteps ]

    [@registerInputSeeder
        id=LOADER_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToInputPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=LOADER_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function loader_inputseeder_commandlineoptions filter state]

    [#return
        mergeObjects(
            state,
            {
                "CommandLineOptions" : {
                    "Deployment" : {
                        "Framework" : {
                            "Name" : DEFAULT_DEPLOYMENT_FRAMEWORK
                        }
                    },
                    "Flow" : {
                        "Names" : [ "views" ]
                    },
                    "View" : {
                        "Name" : LOADER_VIEW_TYPE
                    }
                }
            }
        )
    ]

[/#function]

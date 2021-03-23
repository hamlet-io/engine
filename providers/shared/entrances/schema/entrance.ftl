[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_schema ]

  [@generateOutput
    deploymentFramework=getCLODeploymentFramework()
    type=getCLODeploymentOutputType()
    format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_schema_inputsteps ]

    [@registerInputSeeder
        id=SCHEMA_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=SCHEMA_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function schema_configseeder_commandlineoptions filter state]

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
                        "Name" : SCHEMA_VIEW_TYPE
                    }
                }
            }
        )
    ]

[/#function]

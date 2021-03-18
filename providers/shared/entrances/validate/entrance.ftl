[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_validate ]

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
[#macro shared_entrance_validate_inputsteps ]

    [@registerInputSeeder
        id=VALIDATE_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToInputPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=VALIDATE_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view and enable validation --]
[#function validate_inputseeder_commandlineoptions filter state]

    [#return
        mergeObjects(
            state,
            {
                "CommandLineOptions" : {
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
            }
        )
    ]

[/#function]

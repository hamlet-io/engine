[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_blueprint ]

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
[#macro shared_entrance_blueprint_inputsteps ]

    [@registerInputSeeder
        id=BLUEPRINT_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=BLUEPRINT_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function blueprint_configseeder_commandlineoptions filter state]

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
                        "Name" : BLUEPRINT_VIEW_TYPE
                    }
                }
            }
        )
    ]

[/#function]


[#ftl]

[@registerInputSeeder
    id=SHAREDTEST_INPUT_SEEDER
    description="Shared inputs"
/]

[@addSeederToConfigPipeline
    stage=MASTERDATA_SHARED_INPUT_STAGE
    seeder=SHAREDTEST_INPUT_SEEDER
/]

[@addSeederToConfigPipeline
    stage=FIXTURE_SHARED_INPUT_STAGE
    seeder=SHAREDTEST_INPUT_SEEDER
/]

[#-- Masterdata seeders --]
[#function sharedtest_configseeder_masterdata filter state]

    [#return
        addToConfigPipelineClass(
            state,
            BLUEPRINT_CONFIG_INPUT_CLASS,
            {
                "DeploymentGroups" : {
                    "internal" : {
                        "Priority" : 500,
                        "DistrictType" : "segment",
                        "Level" : "solution",
                        "ResourceSets" : {}
                    }
                }
            },
            MASTERDATA_SHARED_INPUT_STAGE
        )
    ]

[/#function]

[#-- Blueprint seeders --]
[#function sharedtest_configseeder_fixture filter state]
    [#return
        addToConfigPipelineClass(
            state,
            BLUEPRINT_CONFIG_INPUT_CLASS,
            {
                "Product" : {
                    "Modules" : {
                        "dynamicvalue" : {
                            "Provider" : "sharedtest",
                            "Name" : "dynamicvalue"
                        },
                        "internaltest" : {
                            "Provider" : "sharedtest",
                            "Name" : "internaltest"
                        },
                        "runbook" : {
                            "Provider" : "sharedtest",
                            "Name" : "runbook"
                        }
                    }
                },
                "PlacementProfiles": {
                    "internal": {
                        "default": {
                            "Provider": "sharedtest",
                            "Region": "internal",
                            "DeploymentFramework": "default"
                        }
                    }
                }
            },
            FIXTURE_SHARED_INPUT_STAGE
        )
    ]

[/#function]

[#ftl]

[@registerInputSeeder
    id=SHAREDTEST_INPUT_SEEDER
    description="Shared inputs"
/]

[@addSeederToConfigPipeline
    stage=MASTERDATA_SHARED_INPUT_STAGE
    seeder=SHAREDTEST_INPUT_SEEDER
/]

[#-- Masterdata seeders --]
[#function sharedtest_configseeder_masterdata filter state]

    [#return
        mergeObjects(
            state,
            {
                "Masterdata" : {
                    "DeploymentGroups" : {
                        "internal" : {
                            "Priority" : 500,
                            "Level" : "solution",
                            "ResourceSets" : {}
                        }
                    }
                }
            }
        )
    ]

[/#function]

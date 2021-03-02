[#ftl]

[@addInputSeeder
    id=SHARED_INPUT_SEEDER
    description="Shared inputs"
/]

[@addSeederToInputStage
    inputStage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
    inputSeeder=SHARED_INPUT_SEEDER
/]

[@addSeederToInputStage
    inputStage=MASTERDATA_SHARED_INPUT_STAGE
    inputSeeder=SHARED_INPUT_SEEDER
/]

[@addSeederToInputStage
    inputStage=QUALIFY_SHARED_INPUT_STAGE
    inputSeeder=SHARED_INPUT_SEEDER
/]

[#macro shared_inputloader path]
    [#assign shared_cmdb_masterdata =
        (
            getPluginTree(
                path,
                {
                    "AddStartingWildcard" : false,
                    "AddEndingWildcard" : false,
                    "MinDepth" : 1,
                    "MaxDepth" : 1,
                    "FilenameGlob" : "masterdata.json"
                }
            )[0].ContentsAsJSON
        )!{}
    ]
[/#macro]

[#function shared_inputseeder_masterdata filter state]

    [#return
        mergeObjects(
            state,
            {
                "Masterdata" : shared_cmdb_masterdata
            }
        )
    ]

[/#function]

[#function shared_inputseeder_commandlineoptions filter state]

    [#return
        mergeObjects(
            state,
            {
                "CommandLineOptions" : {
                    [#-- Entrance --]
                    "Entrance" : {
                        "Type" : entrance!"deployment"
                    },
                    [#-- Flows --]
                    "Flow" : {
                        "Names" : asArray( flows?split(",") )![]
                    },
                    [#-- Input data control --]
                    "Input" : {
                        "Source" : inputSource!"composite"
                    },
                    [#-- load the plugin state from setup --]
                    "Plugins" : {
                        "State" : (pluginState!"")?has_content?then(
                                        pluginState?eval,
                                        {}
                        )
                    },
                    [#-- Deployment Details --]
                    "Deployment" : {
                        "Provider" : {
                            "Names" : combineEntities(
                                            (providers!"")?has_content?then(
                                                providers?split(","),
                                                []
                                            ),
                                            (commandLineOptions.Deployment.Provider.Names)![],
                                            UNIQUE_COMBINE_BEHAVIOUR
                                        )
                        },
                        "Framework" : {
                            "Name" : deploymentFramework!"default"
                        },
                        "Output" : {
                            "Type" : outputType!"",
                            "Format" : outputFormat!"",
                            "Prefix" : outputPrefix!""
                        },
                        "Group" : {
                            "Name" : deploymentGroup!""
                        },
                        "Unit" : {
                            "Name" : deploymentUnit!"",
                            "Subset" : deploymentUnitSubset!"",
                            "Alternative" : alternative!""
                        },
                        "ResourceGroup" : {
                            "Name" : resourceGroup!""
                        },
                        "Mode" : deploymentMode!""
                    },
                    [#-- Layer Details --]
                    "Layers" : {
                        "Tenant" : tenant!"",
                        "Account" : account!"",
                        "Product" : product!"",
                        "Environment" : environment!"",
                        "Segment" : segment!""
                    },
                    [#-- Logging Details --]
                    "Logging" : {
                        "Level" : logLevel!""
                    },
                    [#-- RunId details --]
                    "Run" : {
                        "Id" : runId!""
                    }
                }
            }
        )
    ]

[/#function]

[#function shared_inputseeder_qualify filter state]

    [#-- Now process the qualifications, validating on the basis of known user filter attributes --]
    [#return
        qualifyEntity(
            state,
            filter,
            getQualifierChildren(getKnownUserInputFilterAttributes())
        )
    ]
[/#function]

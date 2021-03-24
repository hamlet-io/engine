[#ftl]

[@registerInputSeeder
    id=SHARED_INPUT_SEEDER
    description="Shared inputs"
/]

[@registerInputTransformer
    id=SHARED_INPUT_SEEDER
    description="Shared inputs"
/]

[@addSeederToConfigPipeline
    stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToConfigPipeline
    stage=MASTERDATA_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToStatePipeline
    stage=FIXTURE_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToStatePipeline
    stage=SIMULATE_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addTransformerToConfigPipeline
    stage=QUALIFY_SHARED_INPUT_STAGE
    transformer=SHARED_INPUT_SEEDER
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

[#-- Command line options seeders --]
[#function shared_configseeder_commandlineoptions filter state]

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
                        "Source" : inputSource!"composite",
                        "Filter" :
                            attributeIfContent("Tenant", tenant!"") +
                            attributeIfContent("Product", product!"") +
                            attributeIfContent("Environment", environment!"") +
                            attributeIfContent("Segment", segment!"") +
                            attributeIfContent("Account", account!"") +
                            attributeIfContent("Region", region!"")
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
                        "Level" : logLevel!"info",
                        "FatalStopThreshold" : logFatalStopThreshold!0
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

[#function shared_configseeder_commandlineoptions_composite filter state]
    [#return
        mergeObjects(
            shared_configseeder_commandlineoptions(filter, state),
            {
                "CommandLineOptions" : {
                    "References" : {
                        "Request" : requestReference!"",
                        "Configuration" : configurationReference!""
                    },
                    "Composites" : {
                        "Blueprint" : (blueprint!"")?has_content?then(
                                            blueprint?eval,
                                            {}
                        ),
                        "Settings" : (settings!"")?has_content?then(
                                            settings?eval,
                                            {}
                        ),
                        "Definitions" : ((definitions!"")?has_content && (!definitions?contains("null")))?then(
                                            definitions?eval,
                                            {}
                        ),
                        "StackOutputs" : (stackOutputs!"")?has_content?then(
                                            stackOutputs?eval,
                                            []
                        )
                    },
                    "Regions" : {
                        "Segment" : region!"",
                        "Account" : accountRegion!""
                    }
                }
            }
        )
    ]
[/#function]

[#function shared_configseeder_commandlineoptions_mock filter state]
    [#return
        mergeObjects(
            shared_configseeder_commandlineoptions(filter, state),
            {
                "CommandLineOptions" : {
                    "Regions" : {
                        "Segment" : "mock-region-1",
                        "Account" : "mock-region-1"
                    },
                    "References" : {
                        "Request" : "SRVREQ01",
                        "Configuration" : "configRef_v123"
                    },
                    "Run" : {
                        "Id" : "runId098"
                    }
                }
            }
        )
    ]
[/#function]

[#function shared_configseeder_commandlineoptions_whatif filter state]
    [#return shared_configseeder_commandlineoptions_composite(filter, state)]
[/#function]

[#-- Masterdata seeders --]
[#function shared_configseeder_masterdata filter state]

    [#return
        mergeObjects(
            state,
            {
                "Masterdata" : shared_cmdb_masterdata
            }
        )
    ]

[/#function]


[#function shared_configseeder_masterdata_mock filter state]
    [#return
        mergeObjects(
            shared_configseeder_masterdata(filter, state),
            {
                "Masterdata" : {
                    "Regions": {
                        "mock-region-1": {
                            "Locality": "MockLand",
                            "Zones": {
                                "a": {
                                    "Title": "Zone A"
                                },
                                "b": {
                                    "Title": "Zone C"
                                }
                            }
                        }
                    }
                }
            }
        )
    ]
[/#function]


[#function shared_stateseeder_mock filter state]

    [#local id = state.Id]
    [#switch id?split("X")?last ]
        [#case URL_ATTRIBUTE_TYPE ]
            [#local value = "https://mock.local/" + id ]
            [#break]
        [#case IP_ADDRESS_ATTRIBUTE_TYPE ]
            [#local value = "123.123.123.123" ]
            [#break]
        [#default]
            [#local value = formatId( "##MockOutput", id, "##") ]
    [/#switch]

    [#return
        mergeObjects(
            state,
            {
                "Value" : value
            }
        )
    ]

[/#function]

[#function shared_stateseeder_simulate filter state]
    [#if ! state.Value?has_content]
        [#return shared_stateseeder_mock(filter, state) ]
    [/#if]
    [#return state]
[/#function]

[#function shared_configtransformer_qualify filter state]

    [#-- Now process the qualifications, validating on the basis of known layer filter attributes --]
    [#return
        qualifyEntity(
            state,
            filter,
            getQualifierChildren(getRegisteredLayerInputFilterAttributeIds())
        )
    ]
[/#function]

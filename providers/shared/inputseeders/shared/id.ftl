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

[@addSeederToConfigPipeline
    stage=LAYERS_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToConfigPipeline
    stage=LAYERCLEANER_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToStatePipeline
    stage=SIMULATE_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[#-- TODO(mfl) Reenable once layers are in the input processing --]
[#-- so the layer ids can be included in the qualifiers         --]
[#--@addTransformerToConfigPipeline
    stage=QUALIFY_SHARED_INPUT_STAGE
    transformer=SHARED_INPUT_SEEDER
/--]

[@addTransformerToConfigPipeline
    stage=PLUGINLOAD_SHARED_INPUT_STAGE
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
                    },

                    [#-- Ouput handling and writing --]
                    "Output" : {
                        "Pass" : pass!"",
                        "FileName" : outputFileName!"",
                        "Writer" : "output_dir",
                        "Directory" : outputDir!""
                    }
                }
            }
        )
    ]
[/#function]

[#function shared_configseeder_commandlineoptions_composite filter state]

    [#local blueprint = (blueprint!"")?has_content?then(
                                            blueprint?eval_json,
                                            {}
                        )]

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
                        "Blueprint" : blueprint,
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
                },
                "Blueprint" : blueprint
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

[#-- Define and setup the layer data so that it can be used by the plugin transformer --]
[#function shared_configseeder_layers filter state]

    [#local commandLineLayers = state["CommandLineOptions"]["Layers"] ]
    [#local blueprint = state["Blueprint"] ]

    [#list layerConfiguration as id, layer ]
        [@addLayerData
            type=layer.Type
            data=(blueprint[layer.ReferenceLookupType])!{}
        /]
        [@setActiveLayer
            type=layer.Type
            commandLineOptionId=(commandLineLayers[layer.Type])!""
            data=(blueprint[layer.Type])!{}
        /]
    [/#list]
    [#return state]
[/#function]

[#function shared_configseeder_layercleaner filter state ]
    [@clearLayerData /]
    [#return state]
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

[#function shared_configtransformer_pluginload filter state]

    [#local entrance = (state["CommandLineOptions"]["Entrance"]["Type"])!"" ]

    [#if entrance != "loader" ]
        [#-- Update the providers list based on the plugins defined in the layer --]
        [#local pluginState = (state["CommandLineOptions"]["Plugins"]["State"])!{}]
        [@addEnginePluginMetadata
            pluginState=pluginState
        /]

        [#-- Look through the active layers and update the providers list to include plugins defined on the layers --]
        [#local definedPlugins = getActivePluginsFromLayers() ]

        [#local providers = [] ]

        [#list definedPlugins?sort_by("Priority") as plugin]
            [#local pluginRequired = plugin.Required]

            [#local definedPluginState = (pluginState["Plugins"][plugin.Id])!{} ]

            [#if pluginRequired && !(definedPluginState?has_content) && plugin.Source != "local" ]
                [@fatal
                    message="Plugin setup not complete"
                    detail="A plugin was required but plugin setup has not been run"
                    context=plugin
                /]
            [/#if]


            [#local pluginProviderMarker = providerMarkers?filter(
                                                marker -> marker.Path?keep_after_last("/") == plugin.Name ) ]

            [#if !(pluginProviderMarker?has_content) && pluginRequired  ]
                [@fatal
                    message="Unable to load required provider"
                    detail="The provider could not be found in the local state - please load hamlet plugins"
                    context=plugin
                /]
                [#continue]
            [/#if]

            [@addPluginMetadata
                id=plugin.Id
                ref=(definedPluginState.ref)!plugin.Source
            /]

            [#local providers += [ plugin.Name ] ]

        [/#list]

        [#local currentProviders = (state["CommandLineOptions"]["Deployment"]["Provider"]["Names"])![] ]

        [#return
            mergeObjects(
                state,
                {
                    "CommandLineOptions" : {
                        "Deployment" : {
                            "Provider" : {
                                "Names" : combineEntities(currentProviders, providers, UNIQUE_COMBINE_BEHAVIOUR )
                            }
                        }
                    }
                }
            )
        ]
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

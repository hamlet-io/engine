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

[@addSeederToConfigPipeline
    stage=FIXTURE_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToConfigPipeline
    stage=CMDB_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToConfigPipeline
    stage=LAYER_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToConfigPipeline
    stage=PLUGIN_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToConfigPipeline
    stage=MODULE_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToConfigPipeline
    stage=NORMALISE_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addTransformerToConfigPipeline
    stage=QUALIFY_SHARED_INPUT_STAGE
    transformer=SHARED_INPUT_SEEDER
/]

[@addSeederToStatePipeline
    stage=FIXTURE_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToStatePipeline
    stage=CMDB_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
/]

[@addSeederToStatePipeline
    stage=SIMULATE_SHARED_INPUT_STAGE
    seeder=SHARED_INPUT_SEEDER
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
        addToConfigPipelineClass(
            state,
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            {
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
                        attributeIfContent("District", district!"") +
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
                    ),
                    "RefreshRequired" :  ((pluginRefreshRequired!"") == "true")
                },

                [#-- Deployment Details --]
                "Deployment" : {
                    "Provider" : {
                        "Names" :
                            (providers!"")?has_content?then(
                                providers?split(","),
                                []
                            )
                    },
                    "Framework" : {
                        "Name" : deploymentFramework!"default"
                    },
                    "Group" : {
                        "Name" : deploymentGroup!""
                    },
                    "Unit" : {
                        "Name" : deploymentUnit!""
                    },
                    "Mode" : deploymentMode!""
                },

                [#-- Logging Details --]
                "Logging" : {
                    "Level" : logLevel!"info",
                    "StopLevel" : stopLevel!"fatal",
                    "FatalStopThreshold" : logFatalStopThreshold!0,
                    "DepthLimit" : logDepthLimit!0,
                    "Format" : logFormat!"compact",
                    "Writers" :
                        (logWriters!"")?has_content?then(
                            logWriters?split(","),
                            [
                                "console",
                                "log_file"
                            ]
                        ),
                    "FileName" : logFileName!((outputFileName!"")?ensure_ends_with(".log")),
                    "Directory" : (logDir!outputDir)!""
                },

                [#-- RunId details --]
                "Run" : {
                    "Id" : runId!""
                },

                [#-- Ouput handling and writing --]
                "Output" : {
                    "FileName" : outputFileName!"",
                    "Directory" : outputDir!"",
                    "Writers" :
                        (outputWriters!"")?has_content?then(
                            outputWriters?split(","),
                            [
                                "output_dir"
                            ]
                        )
                },

                [#-- Generation Contract Stages --]
                "Contract" : {
                    "Stage" : (generationContractStage!"")?has_content?then(
                                    generationContractStage?eval_json,
                                    {}
                                )
                }
            }
        )
    ]
[/#function]

[#function shared_configseeder_commandlineoptions_composite filter state]
    [#return
        addToConfigPipelineClass(
            shared_configseeder_commandlineoptions(filter, state),
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            {
                "References" : {
                    "Request" : requestReference!"",
                    "Configuration" : configurationReference!""
                },
                "Regions" : {
                    "Segment" : region!"",
                    "Account" : accountRegion!""
                }
            }
        )
    ]

[/#function]

[#function shared_configseeder_commandlineoptions_mock filter state]
    [#return
        addToConfigPipelineClass(
            shared_configseeder_commandlineoptions(filter, state),
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            {
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
        )
    ]
[/#function]

[#function shared_configseeder_commandlineoptions_whatif filter state]
    [#return shared_configseeder_commandlineoptions_composite(filter, state)]
[/#function]

[#-- Masterdata seeders --]
[#function shared_configseeder_masterdata filter state]
    [#return
        addToConfigPipelineStageCacheForClass(
            state,
            BLUEPRINT_CONFIG_INPUT_CLASS,
            shared_cmdb_masterdata,
            MASTERDATA_SHARED_INPUT_STAGE
        )
    ]
[/#function]


[#function shared_configseeder_masterdata_mock filter state]
    [#return
        addToConfigPipelineStageCacheForClass(
            shared_configseeder_masterdata(filter, state),
            BLUEPRINT_CONFIG_INPUT_CLASS,
            {
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
            },
            MASTERDATA_SHARED_INPUT_STAGE
        )
    ]
[/#function]

[#function shared_configseeder_fixture filter state]
    [#return
        addToConfigPipelineClass(
            state,
            BLUEPRINT_CONFIG_INPUT_CLASS,
            {
                "Tenant": {
                    "Id": "mockten",
                    "CertificateBehaviours": {
                        "External": true
                    }
                },
                "Account": {
                    "Region": "mock-region-1",
                    "Domain": "mock",
                    "Audit": {
                        "Offline": 90,
                        "Expiration": 2555
                    },
                    "Id": "mockacct",
                    "Seed": "abc123",
                    "ProviderId": "0123456789"
                },
                "Product": {
                    "Id": "mockedup",
                    "Region": "mock-region-1",
                    "Domain": "mockedup",
                    "Profiles": {
                        "Placement": "default"
                    }
                },
                "Environment": {
                    "Id": "int",
                    "Name": "integration"
                },
                "Segment": {
                    "Id": "default",
                    "Bastion": {
                        "Active": false
                    },
                    "multiAZ": true
                },
                "IPAddressGroups": {},
                "Domains": {
                    "Validation": "mock.local",
                    "mockdomain": {
                        "Stem": "mock.local"
                    }
                },
                "Certificates": {
                    "mockedup": {
                        "Domain": "mockdomain"
                    }
                },
                "Solution": {
                    "Id": "mockapp"
                }
            },
            FIXTURE_SHARED_INPUT_STAGE
        )
    ]
[/#function]


[#function shared_configseeder_cmdb filter state]
    [#-- Handle any composites --]
    [#local result = state]

    [#local compositeBlueprint = (blueprint!"")?has_content?then(blueprint?eval, {}) ]

    [#if compositeBlueprint?has_content]
        [#-- Blueprint needed for plugin/module determination --]
        [#local result =
            addToConfigPipelineClass(
                result,
                BLUEPRINT_CONFIG_INPUT_CLASS,
                compositeBlueprint,
                CMDB_SHARED_INPUT_STAGE
            )
        ]
    [/#if]

    [#local compositeSettings = (settings!"")?has_content?then(settings?eval, {}) ]

    [#if compositeSettings?has_content]
        [#-- Cache settings ready for normalisation --]
        [#local result =
            addToConfigPipelineStageCacheForClass(
                result,
                SETTINGS_CONFIG_INPUT_CLASS,
                normaliseCompositeSettings(compositeSettings),
                CMDB_SHARED_INPUT_STAGE
            )
        ]
    [/#if]

    [#local compositeDefinitions =
        ((definitions!"")?has_content && (!definitions?contains("null")))?then(
            definitions?eval,
            {}
        )
    ]
    [#if compositeDefinitions?has_content]
        [#-- Cache definitions ready for normalisation --]
        [#local result =
            addToConfigPipelineStageCacheForClass(
                result,
                DEFINITIONS_CONFIG_INPUT_CLASS,
                compositeDefinitions,
                CMDB_SHARED_INPUT_STAGE
            )
        ]
    [/#if]

    [#local compositeStackOutputs = (stackOutputs!"")?has_content?then(stackOutputs?eval, []) ]

    [#if compositeStackOutputs?has_content]
        [#-- Cache stack outputs ready for normalisation --]
        [#local result =
            addToConfigPipelineStageCacheForClass(
                result,
                STATE_CONFIG_INPUT_CLASS,
                (stackOutputs!"")?has_content?then(
                    stackOutputs?eval,
                    []
                ),
                CMDB_SHARED_INPUT_STAGE
            )
        ]
    [/#if]

    [#if fragmentTemplate?has_content]
        [#-- Fragments are not affected by plugin/module determination --]
        [#local result =
            addToConfigPipelineClass(
                result,
                FRAGMENTS_CONFIG_INPUT_CLASS,
                fragmentTemplate
            )
        ]
    [/#if]
    [#return result]

[/#function]

[#function shared_configseeder_layer filter state]

    [#local result = state]

    [#-- At this stage, the state should only contain content contributed to --]
    [#-- the blueprint class via fixtures or cmdb. To avoid false errors for --]
    [#-- required layer attributes, ensure we have data to process           --]
    [#if state[BLUEPRINT_CONFIG_INPUT_CLASS]?has_content]
        [#-- Calculate the layers from the blueprint data so far                  --]
        [#-- Include masterdata that to this point is only in the cache           --]
        [#-- Exclude module data - it shouldn't contribute to layer determination --]
        [#-- and should only be added by a subsequent module stage                --]
        [#local config =
            getConfigPipelineClassCacheForStages(
                state,
                BLUEPRINT_CONFIG_INPUT_CLASS,
                [
                    MASTERDATA_SHARED_INPUT_STAGE,
                    FIXTURE_SHARED_INPUT_STAGE,
                    CMDB_SHARED_INPUT_STAGE
                ]
            )[BLUEPRINT_CONFIG_INPUT_CLASS]
        ]

        [#-- A layer is considered active if its attribute is present in the input filter --]

        [#-- Support qualification on the basis of the ids or names of the active layers --]
        [#local enrichedFilter = getEnrichedFilter(filter, friendGetActiveLayersFilter(filter, config)) ]

        [#-- Convert the layer input filter ids to their equivalent attribute configuration --]
        [#local qualifierChildren = getQualifierChildren(getRegisteredLayerInputFilterAttributeIds(filter)) ]

        [#-- Capture the state of the active layers --]
        [#local result =
            addToConfigPipelineClass(
                state,
                ACTIVE_LAYERS_CONFIG_INPUT_CLASS,
                friendGetActiveLayersState(
                    filter,
                    qualifyEntity(config, enrichedFilter, qualifierChildren)
                )
            )
        ]
    [/#if]

    [#return result]

[/#function]

[#function shared_configseeder_plugin filter state]
    [#local plugins = [] ]

    [#-- Check for plugins configured in the CMDB --]
    [#local layersState = state[ACTIVE_LAYERS_CONFIG_INPUT_CLASS]!{} ]
    [#if layersState?has_content]
        [#local plugins = getActivePluginsFromLayers(layersState) ]
    [/#if]

    [#-- At a minimum, need providers from the command line --]
    [#local providers = (state[COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS].Deployment.Provider.Names) ]

    [#-- And for now, load plugins as providers as well --]
    [#list plugins as plugin]
        [#local providers = combineEntities(providers, plugin.Name, UNIQUE_COMBINE_BEHAVIOUR) ]
    [/#list]

    [#-- Determine if the required providers are already loaded --]
    [#local unloadedProviders = getUnloadedProviders(providers) ]
    [#if unloadedProviders?has_content]
        [@debug
            message="Unloaded providers"
            context=unloadedProviders
            detail=unloadedProviders?has_content
            enabled=false
        /]
    [/#if]
    [#return
        addToConfigPipelineClass(
            state,
            LOADER_CONFIG_INPUT_CLASS,
            {
                "Plugins" : plugins,
                "Providers" : providers
            }
        ) +
        [#-- Force a restart of inpout processing if required --]
        {
            "RestartRequired" : unloadedProviders?has_content
        }
    ]
[/#function]

[#function shared_configseeder_module filter state]
    [#local activeModules = [] ]

    [#-- Check for modules configured in the CMDB --]
    [#local layersState = state[ACTIVE_LAYERS_CONFIG_INPUT_CLASS]!{} ]
    [#if layersState?has_content]
        [#local activeModules = getActiveModulesFromLayers(layersState) ]
    [/#if]

    [#local moduleState = {} ]
    [#if activeModules?has_content &&
            [#-- Don't try to load modules when refreshing plugin state --]
            !state[COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS].Plugins.RefreshRequired]
        [@debug
            message="Active modules"
            context=activeModules
            enabled=false
        /]
        [#list activeModules as module ]
            [#-- loadModule will populate this variable assuming the module has been loaded --]
            [#assign moduleInputState = {} ]

            [@seedModuleData
                provider=module.Provider
                name=module.Name
                parameters=module.Parameters
            /]
            [#local moduleState =
                combineEntities(
                    moduleState,
                    moduleInputState,
                    APPEND_COMBINE_BEHAVIOUR
                )
            ]
        [/#list]
        [#return
            [#-- Cache data ready for normalisation --]
            addToConfigPipelineStageCache(
                state,
                moduleState,
                MODULE_SHARED_INPUT_STAGE
            )
        ]
    [/#if]
    [#return state]
[/#function]

[#function shared_configseeder_normalise filter state]

    [#local result = state ]
    [#-- reorganise input classes to implement correct overrides --]
    [#-- master data, fixtures, modules, cmdb --]
    [#list
        [
            BLUEPRINT_CONFIG_INPUT_CLASS,
            SETTINGS_CONFIG_INPUT_CLASS,
            DEFINITIONS_CONFIG_INPUT_CLASS
        ] as class]

        [#local result =
            addToConfigPipelineClass(
                result,
                class,
                (getConfigPipelineClassCacheForStages(
                    state,
                    class,
                    [
                        MASTERDATA_SHARED_INPUT_STAGE,
                        FIXTURE_SHARED_INPUT_STAGE,
                        MODULE_SHARED_INPUT_STAGE,
                        CMDB_SHARED_INPUT_STAGE
                    ]
                )[class])!{}
            )
        ]
    [/#list]

    [#-- Handle AWS/pseudo stacks --]
   [#local result =
        addToConfigPipelineClass(
            result,
            STATE_CONFIG_INPUT_CLASS,
            internalNormaliseAWSStacks(
                (getConfigPipelineClassCacheForStages(
                    state,
                    STATE_CONFIG_INPUT_CLASS,
                    [
                        FIXTURE_SHARED_INPUT_STAGE,
                        MODULE_SHARED_INPUT_STAGE,
                        CMDB_SHARED_INPUT_STAGE
                    ]
                )[STATE_CONFIG_INPUT_CLASS])![]
            ),
            "",
            APPEND_COMBINE_BEHAVIOUR
        )
    ]

    [#return result]

[/#function]

[#function shared_configtransformer_qualify filter state]

    [#-- Provided filter is enriched to include ids and names for any --]
    [#-- previously identified active layer                           --]
    [#-- Qualifications are validated on the basis of known layer     --]
    [#-- filter attributes                                            --]
    [#local enrichedFilter =
        getEnrichedFilter(
            filter,
            friendGetActiveLayersFilterFromLayerState(state[ACTIVE_LAYERS_CONFIG_INPUT_CLASS])
        )
    ]
    [#local qualifierChildren = getQualifierChildren(getRegisteredLayerInputFilterAttributeIds(filter)) ]
    [#return
        qualifyEntity(state, enrichedFilter, qualifierChildren) +
        {
            "QualifierState" : qualifyEntity(state, enrichedFilter, qualifierChildren, "annotate")
        }
    ]
[/#function]

[#function shared_stateseeder_fixture filter state]

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

[#function shared_stateseeder_cmdb filter state]

    [#-- State is assumed to have been normalised to a list of point sets, each of which --]
    [#-- has an account and region, along with one or more point values identified by    --]
    [#-- an id                                                                           --]
    [#-- It is also assumed that the filter has been applied to the point sets as part   --]
    [#-- of the config pipeline                                                          --]
    [#list getState() as pointSet]
        [#if
            (
                (!state.Account?has_content) ||
                ((pointSet.Account) == state.Account)
            ) &&
            (
                (!state.Region?has_content) ||
                (pointSet.Region == state.Region)
            ) &&
            (
                (!state.DeploymentUnit?has_content) ||
                (pointSet.DeploymentUnit == state.DeploymentUnit)
            ) &&
            (pointSet[state.Id]?has_content)
        ]
            [#return
                {
                    "Account" : pointSet.Account,
                    "Region" : pointSet.Region,
                    "Level" : pointSet.Level,
                    "DeploymentUnit" : pointSet.DeploymentUnit,
                    "Value" : pointSet[state.Id]
                }
            ]
        [/#if]
    [/#list]

    [#return state]
[/#function]

[#function shared_stateseeder_simulate filter state]
    [#if ! state.Value?has_content]
        [#return shared_stateseeder_fixture(filter, state) ]
    [/#if]
    [#return state]
[/#function]

[#----------------------------------------------------
-- Internal support functions for shared seeder     --
------------------------------------------------------]

[#-- Normalise aws/pseudo stacks to internal format --]
[#function internalNormaliseAWSStacks stackFiles]

    [#-- Normalise each stack to a point set --]
    [#local pointSets = [] ]

    [#-- Looks like format from aws cli cloudformation describe-stacks command? --]
    [#-- TODO(mfl) Remove check for .Content[0] once dynamic CMDB loading operational --]
    [#list stackFiles?filter(s -> ((s.ContentsAsJSON!s.Content[0]).Stacks)?has_content) as stackFile]
        [#list (stackFile.ContentsAsJSON!stackFile.Content[0]).Stacks?filter(s -> s.Outputs?has_content) as stack ]
            [#local pointSet = {} ]

            [#if stack.Outputs?is_sequence ]
                [#list stack.Outputs as output ]
                    [#local pointSet += {
                        output.OutputKey : output.OutputValue
                    }]
                [/#list]
            [/#if]

            [#if stack.Outputs?is_hash ]
                [#local pointSet = stack.Outputs ]
            [/#if]

            [#if pointSet?has_content ]
                [@debug
                    message="Normalise stack file " + stackFile.FileName!""
                    enabled=false
                /]
                [#local pointSets +=
                    [
                        validatePointSet(
                            mergeObjects(
                                { "Level" : (stackFile.FileName!"")?split('-')[0]},
                                pointSet
                            )
                            )
                    ]
                ]
            [/#if]
        [/#list]
    [/#list]

    [#return pointSets]
[/#function]

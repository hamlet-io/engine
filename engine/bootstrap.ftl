[#ftl]

[#-- Core helper routines --]
[#include "base.ftl" ]
[#include "engine.ftl"]
[#include "common.ftl"]

[#-- flow --]
[#include "flow.ftl" ]

[#-- logging --]
[#include "logging.ftl" ]

[#-- AttributeSets --]
[#include "attributeset.ftl"]

[#-- Input data handling --]
[#include "inputdata/inputsource.ftl" ]
[#include "inputdata/layer.ftl" ]
[#include "inputdata/commandLineOptions.ftl" ]
[#include "inputdata/masterdata.ftl" ]
[#include "inputdata/blueprint.ftl" ]
[#include "inputdata/reference.ftl" ]
[#include "inputdata/setting.ftl" ]
[#include "inputdata/stackOutput.ftl" ]
[#include "inputdata/definition.ftl" ]
[#include "inputdata/seed.ftl" ]


[#-- entrances --]
[#include "entrance.ftl" ]

[#-- Task loading --]
[#include "task.ftl" ]

[#-- Resource Labels --]
[#include "resourceLabel.ftl" ]

[#-- Module Loading --]
[#include "module.ftl" ]

[#-- Extension loading --]
[#include "extension.ftl" ]

[#-- Component handling --]
[#include "component.ftl" ]

[#-- Service Handling --]
[#include "services.ftl" ]

[#-- View handling --]
[#include "view.ftl" ]

[#--Occurrence handling --]
[#include "occurrence.ftl"]
[#include "link.ftl"]

[#-- Output handling --]
[#include "output.ftl" ]

[#-- openapi handling --]
[#include "openapi.ftl"]

[#-- Schema handling --]
[#include "schema.ftl"]

[#-- Provider handling --]
[#include "provider.ftl" ]
[@initialiseProviders /]

[#-- Load and setup the basics of the shared provider --]
[@includeProviders SHARED_PROVIDER /]
[@seedProviderInputSourceData
    providers=[ SHARED_PROVIDER ]
    inputTypes=[ "commandlineoption" ]

/]
[@includeCoreProviderConfiguration SHARED_PROVIDER /]
[@seedProviderInputSourceData
    providers=[ SHARED_PROVIDER ]
    inputTypes=[ "masterdata", "blueprint" ]
/]

[#-- Set desired logging level --]
[@setLogLevel commandLineOptions.Logging.Level /]

[#-- Setup the contract outputs before invoking the entrance to allow for errors to be caught --]
[@setupContractOutputs /]

[#-- Update the providers list based on the plugins defined in the layer --]
[@addEnginePluginMetadata commandLineOptions.Plugins.State /]

[#if commandLineOptions.Entrance.Type != "loader" ]
    [@includeLayers /]
    [@addPluginsFromLayers commandLineOptions.Plugins.State /]
    [@clearLayerData /]
[/#if]

[#-- Load providers base on the providers list  --]
[@includeProviders commandLineOptions.Deployment.Provider.Names /]
[@seedProviderInputSourceData
    providers=commandLineOptions.Deployment.Provider.Names
    inputTypes=[ "commandlineoption" ]
/]

[@includeCoreProviderConfiguration commandLineOptions.Deployment.Provider.Names /]

[#-- TODO(MFL) Following can be deleted I think as it just does what the next piece --]
[#-- processing will repeat                                                         --]
[#--]
[@seedProviderInputSourceData
    providers=commandLineOptions.Deployment.Provider.Names
    inputTypes=[ "masterdata" ]
/]
--]

[#-- Input data Seeding --]
[#-- This controls the collection of all input data provided to the engine --]
[#assign refreshInputData = false ]
[#assign seedProviders = [ SHARED_PROVIDER, commandLineOptions.Deployment.Provider.Names ]]
[#assign seedInputTypes = [ "masterdata", "blueprint", "stackoutput", "setting", "definition" ]]

[@seedProviderInputSourceData
    providers=seedProviders
    inputTypes=seedInputTypes
/]

[#-- Set the base of blueprint from the provider masterdata --]
[#-- Rebase is needed to ensure any overrides of master     --]
[#-- data within the blueprint don't get overwritten        --]
[@rebaseBlueprint base=getMasterData() /]

[#-- Discover the layers which have been defined --]
[#-- This needs to be done before module loading as layers define the modules to load and their parameters --]
[#-- This also has the added benefit of locking layers, since they are specific to a deployment people shouldn't be modifying layers with modules --]
[@includeLayers /]

[#-- Load Modules --]
[#assign activeModules = getActiveModulesFromLayers() ]
[#if activeModules?has_content ]
    [#assign refreshInputData = true ]
    [#list activeModules as module ]
        [@seedModuleData
            provider=module.Provider
            name=module.Name
            parameters=module.Parameters
        /]
    [/#list]
[/#if]

[#-- TODO(MFL) Code below needs reviewing                                  --]
[#-- As modules will have potentially added to the various types of input, --]
[#-- it seems odd to then replay the inputs over the top of this again     --]
[#-- Is this to ensure whatever was explicitly provided takes precedence   --]
[#-- over modules? Think we don't want that for master data but do for     --]
[#-- everything else                                                       --]

[#-- Refresh seed to allow for data from modules to be included --]
[#if refreshInputData ]
    [@seedProviderInputSourceData
        providers=seedProviders
        inputTypes=[ "blueprint", "stackoutput", "setting", "definition" ]
    /]
[/#if]

[#-- Load reference data for any references defined by providers --]
[@includeReferences /]

[#-- Set the context for templates processing --]
[#include "setContext.ftl" ]

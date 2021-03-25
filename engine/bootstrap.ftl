[#ftl]

[#-- Core helper routines --]
[#include "base.ftl" ]
[#include "engine.ftl"]
[#include "common.ftl"]

[#-- logging --]
[#include "logging.ftl" ]

[#-- flow --]
[#include "flow.ftl" ]

[#-- AttributeSets --]
[#include "attributeset.ftl"]

[#-- Input data handling --]
[#include "inputdata/inputsource.ftl" ]
[#include "inputdata/layer.ftl" ]
[#include "inputdata/commandLineOptions.ftl" ]
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
[#include "output_writer.ftl" ]

[#-- openapi handling --]
[#include "openapi.ftl"]

[#-- Schema handling --]
[#include "schema.ftl"]

[#-- Provider handling --]
[#include "provider.ftl" ]
[@initialiseProviders /]

[#-- Load and setup the basics of the shared provider   --]
[#-- This will configure the bootstrap input source     --]
[#-- which means command line options will be available --]
[@includeProviders SHARED_PROVIDER /]
[@includeCoreProviderConfiguration SHARED_PROVIDER /]

[#-- Set desired logging configuration  --]
[@setLogLevel getCommandLineOptions().Logging.Level /]
[@setLogFatalStopThreshold getCommandLineOptions().Logging.FatalStopThreshold /]

[#-- Reinitialise the input system based on the CLO input source and filter --]
[@initialiseInputProcessing
    inputSource=getCLOInputSource()
    inputFilter=getCLOInputFilter()
/]

[@seedProviderInputSourceData
    providers=[ SHARED_PROVIDER ]
    inputTypes=[ "blueprint" ]
/]

[#-- Setup the contract outputs before invoking the entrance to allow for errors to be caught --]
[@setupContractOutputs /]

[#-- Load providers based on the providers list  --]
[@includeProviders getCLODeploymentProviders() /]
[@includeCoreProviderConfiguration getCLODeploymentProviders() /]

[#-- Input data Seeding --]
[#-- This controls the collection of all input data provided to the engine --]
[#assign refreshInputData = false ]
[#assign seedProviders = [ SHARED_PROVIDER, getCLODeploymentProviders() ]]
[#assign seedInputTypes = [ "blueprint", "stackoutput", "setting", "definition" ]]

[@seedProviderInputSourceData
    providers=seedProviders
    inputTypes=seedInputTypes
/]

[#-- Reinitialise the input system including the provider if available    --]
[#-- This will include the provider specific seeders in the input process --]
[@initialiseInputProcessing
    inputSource=getInputSource()
    inputFilter=getInputFilter() + getProviderFilter()
/]

[#-- Set the base of blueprint from the provider masterdata --]
[#-- Rebase is needed to ensure any overrides of master     --]
[#-- data within the blueprint don't get overwritten        --]
[@rebaseBlueprint base=getMasterdata() /]

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

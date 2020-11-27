[#ftl]

[#-- Core helper routines --]
[#include "base.ftl" ]
[#include "engine.ftl"]
[#include "common.ftl"]

[#-- flow --]
[#include "flow.ftl" ]

[#-- logging --]
[#include "logging.ftl" ]

[#-- Input data handling --]
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

[#-- ObjectInstance handling --]
[#include "objectinstance.ftl" ]

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

[#-- Get common command line options/masterdata --]
[@includeProviders SHARED_PROVIDER /]
[@seedCoreProviderInputSourceData SHARED_PROVIDER /]

[#-- Set desired logging level --]
[@setLogLevel commandLineOptions.Logging.Level /]

[#-- Get the provider specific command line options/masterdata --]
[@includeProviders commandLineOptions.Deployment.Provider.Names /]
[@seedCoreProviderInputSourceData commandLineOptions.Deployment.Provider.Names /]

[#-- start the blueprint with the masterData --]
[@addBlueprint blueprint=getMasterData() /]

[#-- Process the remaining core provider configuration --]
[@includeCoreProviderConfiguration SHARED_PROVIDER /]
[@includeCoreProviderConfiguration commandLineOptions.Deployment.Provider.Names /]

[#-- Determine input source input data --]
[@seedProviderInputSourceData SHARED_PROVIDER, commandLineOptions.Deployment.Provider.Names /]

[#-- Discover the layers which have been defined
[#--This needs to be done before module loading as layers define the modules to load and their parameters --]
[#-- This also has the added benefit of locking layers, since they are specific to a deployment people shouldn't be modifying layers with modules --]
[@includeLayers /]

[#-- Load Modules --]
[#assign refreshInputData = false ]

[#list getActiveModulesFromLayers() as module ]
    [#assign refreshInputData = true ]
    [@seedModuleData
        provider=module.Provider
        name=module.Name
        parameters=module.Parameters
    /]
[/#list]

[#-- refresh the input data once we've loaded the modules to ensure the CMDB is perferred --]
[#if refreshInputData ]
    [@seedProviderInputSourceData SHARED_PROVIDER, commandLineOptions.Deployment.Provider.Names /]
[/#if]

[#-- Load reference data for any references defined by providers --]
[@includeReferences /]

[#-- Set the context for templates processing --]
[#include "setContext.ftl" ]

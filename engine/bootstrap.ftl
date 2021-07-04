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
[#include "inputdata/district.ftl" ]
[#include "inputdata/commandLineOptions.ftl" ]
[#include "inputdata/reference.ftl" ]
[#include "inputdata/setting.ftl" ]
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

[#-- Compute tasks --]
[#include "computetask.ftl" ]

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

[#-- Load and setup the basics of the shared provider            --]
[#-- This will configure the bootstrap input source              --]
[#-- which means command line options will be available          --]
[#-- Note that the plugin stage is NOT included in the bootstrap --]
[#-- so no additional plugins will be loaded automatically       --]
[@includeProviders SHARED_PROVIDER /]
[@includeCoreProviderConfiguration SHARED_PROVIDER /]

[#-- Set desired logging configuration  --]
[@setLogLevel getCommandLineOptions().Logging.Level /]
[@setFatalLogLevel getCommandLineOptions().Logging.StopLevel /]

[@setLogFatalStopThreshold getCommandLineOptions().Logging.FatalStopThreshold /]
[@setLogDepthLimit getCommandLineOptions().Logging.DepthLimit /]

[@addEnginePluginMetadata getCommandLineOptions().Plugins.State /]

[#-- Reinitialise the input system based on the CLO input source and filter --]
[#-- This will cause any CLO plugins/providers to be loaded as well         --]
[@initialiseInputProcessing
    inputSource=getCLOInputSource()
    inputFilter=getCLOInputFilter()
/]

[#-- Setup the contract outputs before invoking the entrance to allow for errors to be caught --]
[@setupContractOutputs /]

[#-- Reinitialise the input system including the provider/region if available    --]
[#-- This will include the provider specific seeders in the input process --]
[@initialiseInputProcessing
    inputSource=getInputSource()
    inputFilter=getAccountLayerFilters(getProductLayerFilters(getInputFilter()))
/]

[#-- Set the context for templates processing --]
[#include "setContext.ftl" ]
[@setContext /]

[#-- Level utility support --]
[#include "commonApplication.ftl"]

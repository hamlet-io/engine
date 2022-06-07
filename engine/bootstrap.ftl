[#ftl]

[#-- Core helper routines --]
[#include "base.ftl" ]
[#include "common.ftl"]
[#include "configuration.ftl"]

[#-- logging --]
[#include "logging.ftl" ]

[#-- flow --]
[#include "flow.ftl" ]

[#-- Dynamic Configuration entry points --]
[#include "configuration/configuration.ftl"]
[#include "configuration/attributeset.ftl"]
[#include "configuration/blueprint.ftl"]
[#include "configuration/component.ftl" ]
[#include "configuration/computetask.ftl" ]
[#include "configuration/entrance.ftl" ]
[#include "configuration/layer.ftl"]
[#include "configuration/module.ftl" ]
[#include "configuration/reference.ftl" ]
[#include "configuration/solution.ftl" ]
[#include "configuration/task.ftl" ]
[#include "configuration/dynamicvalues.ftl" ]

[#-- Input data handling --]
[#include "inputdata/inputsource.ftl" ]
[#include "inputdata/layer.ftl" ]
[#include "inputdata/district.ftl" ]
[#include "inputdata/commandLineOptions.ftl" ]
[#include "inputdata/reference.ftl" ]
[#include "inputdata/setting.ftl" ]
[#include "inputdata/seed.ftl" ]
[#include "inputdata/solution.ftl" ]

[#-- Plugin data loading --]
[#include "extension.ftl" ]
[#include "services.ftl" ]
[#include "resourceLabel.ftl" ]

[#-- View handling --]
[#include "view.ftl" ]

[#--Occurrence handling --]
[#include "occurrence.ftl"]

[#-- Output handling --]
[#include "output.ftl" ]
[#include "output_writer.ftl" ]

[#-- openapi handling --]
[#include "openapi.ftl"]

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

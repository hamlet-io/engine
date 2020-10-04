[#ftl]

[#-- Core helper routines --]
[#include "base.ftl" ]

[#-- model --]
[#include "model.ftl" ]

[#-- context --]
[#include "context.ftl" ]

[#-- logging --]
[#include "logging.ftl" ]

[#-- Input data handling --]
[#include "inputdata/commandLineOptions.ftl" ]
[#include "inputdata/masterdata.ftl" ]
[#include "inputdata/blueprint.ftl" ]
[#include "inputdata/reference.ftl" ]
[#include "inputdata/setting.ftl" ]
[#include "inputdata/stackOutput.ftl" ]
[#include "inputdata/definition.ftl" ]
[#include "inputdata/seed.ftl" ]

[#-- document sets --]
[#include "documentSet.ftl" ]

[#-- Task loading --]
[#include "task.ftl" ]

[#-- Resource Labels --]
[#include "resourceLabel.ftl" ]

[#-- Scenerio Loading --]
[#include "scenario.ftl" ]
[#include "testcase.ftl" ]

[#-- Component handling --]
[#include "component.ftl" ]

[#--Occurrence handling --]
[#include "occurrence.ftl"]
[#include "link.ftl"]

[#-- Output handling --]
[#include "output.ftl" ]

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

[#-- Load Scenarios --]
[#if scenarioList?has_content ]
    [@seedScenarioConfiguration
        provider=SHARED_PROVIDER
        scenarios=scenarioList
    /]

    [#list commandLineOptions.Deployment.Provider.Names as provider ]
        [@seedScenarioConfiguration
            provider=provider
            scenarios=scenarioList
        /]
    [/#list]
[/#if]

[#-- Determine input source input data --]
[@seedProviderInputSourceData SHARED_PROVIDER, commandLineOptions.Deployment.Provider.Names /]

[#-- Set the context for templates processing --]
[#include "setContext.ftl" ]

[#-- Populate the model to be used --]
[#assign model =
    invokeFunction(
        getFirstDefinedDirective(
            [
                [commandLineOptions.Deployment.Framework.Name, "model", commandLineOptions.Deployment.Framework.Model],
                [DEFAULT_DEPLOYMENT_FRAMEWORK, "model", commandLineOptions.Deployment.Framework.Model]
            ]
        )
    ) ]

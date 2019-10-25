[#ftl]

[#-- Core helper routines --]
[#include "base.ftl" ]

[#-- Command line options are used to control the engine so make sure we load them first --]
[#include "inputdata/commandLineOptions.ftl" ]

[#-- Input data control --]
[@addCommandLineOption
    option={
        "Input" : {
            "Source" : inputSource!"composite",
            "Scenarios" : (scenarios?split(","))![],
            "TestCase" : testCase!""
        }
    }
/]

[#-- Deployment Details --]
[@addCommandLineOption
    option={
        "Deployment" : {
            "Provider" : {
                "Name" : provider!""
            },
            "Framework" : {
                "Name" : deploymentFramework!"",
                "Model" : deploymentFrameworkModel!"legacy"
            },
            "Output" : {
                "Type" : outputType!"",
                "Format" : outputFormat!""
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
        }
    }
/]

[#-- Logging Details --]
[@addCommandLineOption
    option={
        "Logging" : {
            "Level" : logLevel!""
        }
    }
/]

[#-- RunId details --]
[@addCommandLineOption
    option={
        "Run" : {
            "Id" : runId!""
        }
    }
/]

[#-- Reference metadata --]
[@addCommandLineOption
    option={
        "References" : {
            "Request" : requestReference!"",
            "Configuration" : configurationReference!""
        }
    }
/]

[#-- Composite Inputs --]
[@addCommandLineOption
    option={
        "Composites" : {
            "Blueprint" : (blueprint!"")?has_content?then(
                                blueprint?eval,
                                {}
            ),
            "Settings" : (settings!"")?has_content?then(
                                settings?eval,
                                {}
            ),
            "Definitions" : (definitions!"")?has_content?then(
                                definitions?eval,
                                {}
            ),
            "StackOutputs" : (stackOutputs!"")?has_content?then(
                                stackOutputs?eval,
                                []
            )
        }
    }
/]

[#-- Regions --]
[@addCommandLineOption
    option={
        "Regions" : {
            "Segment" : region!"",
            "Account" : accountRegion!""
        }
    }
/]


[#if !deploymentFrameworkModel??]
    [#assign deploymentFrameworkModel = "legacy"]
[/#if]

[#-- logging --]
[#include "logging.ftl" ]

[#-- Input data handling --]
[#include "inputdata/masterdata.ftl" ]
[#include "inputdata/blueprint.ftl" ]
[#include "inputdata/reference.ftl" ]
[#include "inputdata/setting.ftl" ]
[#include "inputdata/stackOutput.ftl" ]
[#include "inputdata/definition.ftl" ]

[#-- Scenerio Loading --]
[#include "scenario.ftl" ]
[#include "testcase.ftl" ]

[#-- Component handling --]
[#include "component.ftl" ]

[#--Occurrence handling --]
[#include "occurrence.ftl"]
[#include "link.ftl"]

[#-- Provider handling --]
[#include "provider.ftl" ]

[#-- Output handling --]
[#include "output.ftl" ]

[#-- Include any base level input sources --]
[@includeBaseInputSourceConfiguration
    provider=SHARED_PROVIDER
    inputSource="shared"
/]

[#if commandLineOptions.Input.Source?has_content]
    [@includeBaseInputSourceConfiguration
        provider=SHARED_PROVIDER
        inputSource=commandLineOptions.Input.Source
    /]
[/#if]

[#-- Include the shared provider --]
[@includeProviderConfiguration provider=SHARED_PROVIDER /]

[#-- Include any command line based input data source --]
[#if commandLineOptions.Deployment.Provider.Name?has_content ]
    [@includeBaseInputSourceConfiguration
        provider=commandLineOptions.Deployment.Provider.Name
        inputSource="shared"
    /]
    [#if commandLineOptions.Input.Source?has_content]
        [@includeBaseInputSourceConfiguration
            provider=commandLineOptions.Deployment.Provider.Name
            inputSource=commandLineOptions.Input.Source
        /]
    [/#if]
[/#if]

[#-- Include any command line provider --]
[#if commandLineOptions.Deployment.Provider.Name?has_content ]
    [@includeProviderConfiguration provider=commandLineOptions.Deployment.Provider.Name /]
[/#if]

[#-- start the blueprint with the masterData --]
[@addBlueprint blueprint=getMasterData() /]

[#-- Set the scenarios provided via the CLI --]
[@updateScenarioList
    scenarioIds=commandLineOptions.Input.Scenarios
/]

[#-- Load test case if it has been specified --]
[#if (commandLineOptions.Deployment.Unit.Subset!"") == "testplan" ]
    [@initialiseJsonOutput name="testplan" /]
[/#if]

[#if commandLineOptions.Input.TestCase?has_content ]
    [@includeTestCaseConfiguration
        provider=SHARED_PROVIDER
        testCase=commandLineOptions.Input.TestCase
    /]

    [#if commandLineOptions.Deployment.Provider.Name?has_content ]
        [@includeTestCaseConfiguration
            provider=commandLineOptions.Deployment.Provider.Name
            testCase=commandLineOptions.Input.TestCase
        /]
    [/#if]
[/#if]

[#-- Load Scenarios --]
[#if scenarioList?has_content ]
    [@includeScenarioConfiguration
        provider=SHARED_PROVIDER
        scenarios=scenarioList
    /]

    [#if commandLineOptions.Deployment.Provider.Name?has_content ]
        [@includeScenarioConfiguration
            provider=commandLineOptions.Deployment.Provider.Name
            scenarios=scenarioList
        /]
    [/#if]
[/#if]

[#-- Include any shared input sources --]
[@includeInputSourceConfiguration
    provider=SHARED_PROVIDER
    inputSource="shared"
/]

[#if commandLineOptions.Input.Source?has_content]
    [@includeInputSourceConfiguration
        provider=SHARED_PROVIDER
        inputSource=commandLineOptions.Input.Source
    /]
[/#if]

[#-- Include any command line provider/input source --]
[#if commandLineOptions.Deployment.Provider.Name?has_content ]
    [@includeInputSourceConfiguration
        provider=commandLineOptions.Deployment.Provider.Name
        inputSource="shared"
    /]
    [#if commandLineOptions.Input.Source?has_content]
        [@includeInputSourceConfiguration
            provider=commandLineOptions.Deployment.Provider.Name
            inputSource=commandLineOptions.Input.Source
        /]
    [/#if]
[/#if]

[#-- Set the context for templates processing --]
[#include "setContext.ftl" ]

[#-- Always include the default deployment framework --]
[@includeDeploymentFrameworkConfiguration
    provider=SHARED_PROVIDER
    deploymentFramework=DEFAULT_DEPLOYMENT_FRAMEWORK
/]

[#-- Include any shared (multi-provider) deployment framework --]
[#if commandLineOptions.Deployment.Framework.Name?has_content]
    [@includeDeploymentFrameworkConfiguration
        provider=SHARED_PROVIDER
        deploymentFramework=commandLineOptions.Deployment.Framework.Name
    /]
[/#if]

[#-- Include any command line provider/deployment framework --]
[#if commandLineOptions.Deployment.Provider.Name?has_content ]
    [@includeProviderConfiguration provider=commandLineOptions.Deployment.Provider.Name /]
    [#if commandLineOptions.Deployment.Framework.Name?has_content]
        [@includeDeploymentFrameworkConfiguration
            provider=commandLineOptions.Deployment.Provider.Name
            deploymentFramework=commandLineOptions.Deployment.Framework.Name
        /]
    [/#if]
[/#if]

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

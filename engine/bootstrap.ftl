[#ftl]

[#-- Core helper routines --]
[#include "base.ftl" ]

[#-- Command line options are used to control the engine so make sure we load them first --]
[#include "inputdata/commandLineOptions.ftl" ]

[#-- Input data control --]
[@addCommandLineOption
    option={
        "Input" : {
            "Source" : inputSource!"composite"
        }
    }
/]

[#-- Deployment Details --]
[@addCommandLineOption
    option={
        "Scopes" : {
            "Tenant" : tenant!"",
            "Account" : account!"",
            "Product" : product!"",
            "Environment" : environment!"",
            "Segment" : segment!""
        }
    }
/]

[#-- Deployment Details --]
[@addCommandLineOption
    option={
        "Deployment" : {
            "Provider" : {
                "Names" : asArray( providers?split(",") )![]
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

[#-- CMDB Handling --]
[#if commandLineOptions.Input.Source == "composite"]
    [#include "cmdb.ftl" ]
[/#if]

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

[#list commandLineOptions.Deployment.Provider.Names as provider ]
    [#-- Load Input Sources --]
    [@includeBaseInputSourceConfiguration
        provider=provider
        inputSource="shared"
    /]
    [#if commandLineOptions.Input.Source?has_content]
        [@includeBaseInputSourceConfiguration
            provider=provider
            inputSource=commandLineOptions.Input.Source
        /]
    [/#if]

   [#-- Include any command line provider --]
   [@includeProviderConfiguration provider=provider /]
[/#list]


[#-- start the blueprint with the masterData --]
[@addBlueprint blueprint=getMasterData() /]

[#-- Load Scenarios --]
[#if scenarioList?has_content ]
    [@includeScenarioConfiguration
        provider=SHARED_PROVIDER
        scenarios=scenarioList
    /]

    [#list commandLineOptions.Deployment.Provider.Names as provider ]
        [@includeScenarioConfiguration
            provider=provider
            scenarios=scenarioList
        /]
    [/#list]
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
[#list commandLineOptions.Deployment.Provider.Names as provider ]
    [@includeInputSourceConfiguration
        provider=provider
        inputSource="shared"
    /]
    [#if commandLineOptions.Input.Source?has_content]
        [@includeInputSourceConfiguration
            provider=provider
            inputSource=commandLineOptions.Input.Source
        /]
    [/#if]
[/#list]

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
[#list commandLineOptions.Deployment.Provider.Names as provider]
    [@includeProviderConfiguration provider=provider /]
    [#if commandLineOptions.Deployment.Framework.Name?has_content]
        [@includeDeploymentFrameworkConfiguration
            provider=provider
            deploymentFramework=commandLineOptions.Deployment.Framework.Name
        /]
    [/#if]
[/#list]

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

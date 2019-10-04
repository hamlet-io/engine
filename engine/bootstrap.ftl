[#ftl]

[#-- Pull in the provided command line options --]
[#assign commandLineOptions =
    {
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
        },
        "Logging" : {
            "Level" : logLevel!""
        },
        "Run" : {
            "Id" : runId!""
        },
        "Regions" : {
            "Segment" : region!"",
            "Product" : productRegion!"",
            "Account" : accountRegion!""
        },
        "References" : {
            "Request" : requestReference!"",
            "Configuration" : configurationReference!""
        },
        "Composites" : {
            "Blueprint" : (blueprint!"{}")?eval,
            "Settings" : (settings!"{}")?eval,
            "Definitions" : (definitions!"{}")?eval,
            "StackOutputs" : (stackOutputs!"[]")?eval
        },
        "Input" : {
            "Source" : inputSource!"composite"
        }
    } ]

[#if !deploymentFrameworkModel??]
    [#assign deploymentFrameworkModel = "legacy"]
[/#if]

[#-- Core helper routines --]
[#include "base.ftl" ]

[#-- Component handling --]
[#include "component.ftl" ]
[#include "setting.ftl" ]

[#--Occurrence handling --]
[#include "occurrence.ftl"]
[#include "link.ftl"]

[#-- Provider handling --]
[#include "provider.ftl" ]

[#-- Output handling --]
[#include "output.ftl" ]

[#-- Input handling --]
[#include "stackOutput.ftl" ]

[#-- Include any shared input sources --]
[#if commandLineOptions.Input.Source?has_content]
    [@includeInputSourceConfiguration
        provider=SHARED_PROVIDER
        inputSource=commandLineOptions.Input.Source
    /]
[/#if]

[#-- Include any command line provider/input source --]
[#if commandLineOptions.Deployment.Provider.Name?has_content ]
    [@includeProviderConfiguration provider=commandLineOptions.Deployment.Provider.Name /]
    [#if commandLineOptions.Input.Source?has_content]
        [@includeInputSourceConfiguration
            provider=commandLineOptions.Deployment.Provider.Name
            inputSource=commandLineOptions.Input.Source
        /]
    [/#if]
[/#if]

[#-- Set the context for templates processing --]
[#include "setContext.ftl" ]

[#-- Include the shared provider --]
[@includeProviderConfiguration provider=SHARED_PROVIDER /]

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


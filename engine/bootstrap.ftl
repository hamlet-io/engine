[#ftl]

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

[#-- Set the context for templates processing --]
[#include "setContext.ftl" ]

[#-- Include the shared provider --]
[@includeProviderConfiguration provider=SHARED_PROVIDER /]

[#-- Include the default deployment framework --]
[@includeDeploymentFrameworkConfiguration
    provider=SHARED_PROVIDER
    deploymentFramework=DEFAULT_DEPLOYMENT_FRAMEWORK
/]

[#-- Include the provider deployment framework if defined --]
[#if provider?? ]
    [@includeProviderConfiguration provider=provider /]
    [#if deploymentFramework??]
        [@includeDeploymentFrameworkConfiguration
            provider=provider
            deploymentFramework=deploymentFramework
        /]
    [/#if]
[/#if]

[#-- Populate the model to be used --]
[#assign model =
    invokeFunction(
        getFirstDefinedDirective(
            [
                [deploymentFramework, "model", deploymentFrameworkModel!""],
                [DEFAULT_DEPLOYMENT_FRAMEWORK, "model", deploymentFrameworkModel!""]
            ]
        )
    ) ]


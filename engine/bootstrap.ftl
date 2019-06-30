[#ftl]

[#-- Core helper routines --]
[#include "base.ftl" ]

[#-- Provider handling --]
[#include "component.ftl" ]
[#include "provider.ftl" ]

[#-- Output handling --]
[#include "output.ftl"]

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


[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Extra includes for account processing --]
[@includeServicesConfiguration
    provider=AWS_PROVIDER
    services=[AWS_IDENTITY_SERVICE, AWS_WEB_APPLICATION_FIREWALL_SERVICE]
    deploymentFramework=deploymentFramework
/]

[@includeProviderComponentDefinitionConfiguration
    provider=SHARED_PROVIDER
    component=MOBILENOTIFIER_COMPONENT_TYPE
/]
[@includeProviderComponentDefinitionConfiguration
    provider=AWS_PROVIDER
    component=MOBILENOTIFIER_COMPONENT_TYPE
/]

[@includeProviderComponentConfiguration
    provider=AWS_PROVIDER
    component=MOBILENOTIFIER_COMPONENT_TYPE
    services=[AWS_CLOUDWATCH_SERVICE, AWS_SIMPLE_NOTIFICATION_SERVICE]
/]

[#assign categoryId = "account"]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "iam"]
    [#case "lg"]
        [#if (deploymentUnitSubset!"") == "genplan"]
            [@initialiseDefaultScriptOutput format=outputFormat /]
            [@addToDefaultScriptOutput getGenerationPlan("template") /]
        [#else]
            [#if !(deploymentUnitSubset?has_content)]
                [#assign allDeploymentUnits = true]
                [#assign deploymentUnitSubset = deploymentUnit]
                [#assign ignoreDeploymentUnitSubsetInOutputs = true]
            [/#if]
        [/#if]
        [#break]
[/#switch]

[@generateOutput
    deploymentFramework=deploymentFramework
    type=outputType
    format=outputFormat
    include=accountList
/]

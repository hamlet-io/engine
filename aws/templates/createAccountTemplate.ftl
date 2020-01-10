[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Extra includes for account processing --]
[@includeServicesConfiguration
    provider=AWS_PROVIDER
    services=[AWS_IDENTITY_SERVICE, AWS_WEB_APPLICATION_FIREWALL_SERVICE]
    deploymentFramework=commandLineOptions.Deployment.Framework.Name
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
[#switch getDeploymentUnit() ]
    [#case "iam"]
    [#case "lg"]
        [#if (commandLineOptions.Deployment.Unit.Subset!"") == "genplan"]
            [@initialiseDefaultScriptOutput format=commandLineOptions.Deployment.Output.Format /]
            [@addDefaultGenerationPlan subsets="template" /]
        [#else]
            [#if !(commandLineOptions.Deployment.Unit.Subset?has_content)]
                [#assign allDeploymentUnits = true]
                [#assign commandLineOptions =
                    mergeObjects(
                        commandLineOptions,
                        {
                            "Deployment" : {
                                "Unit" : {
                                    "Subset" : getDeploymentUnit()
                                }
                            }
                        }
                    ) ]
                [#assign ignoreDeploymentUnitSubsetInOutputs = true]
            [/#if]
        [/#if]
        [#break]
[/#switch]

[@generateOutput
    deploymentFramework=commandLineOptions.Deployment.Framework.Name
    type=commandLineOptions.Deployment.Output.Type
    format=commandLineOptions.Deployment.Output.Format
    include=accountList
/]

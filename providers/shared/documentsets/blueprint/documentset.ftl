[#ftl]

[#assign allDeploymentUnits = true]

[#-- override the deployment group to get all deployment groups --]
[@addCommandLineOption
    option={
      "Deployment" : {
        "Unit" : {
          "Name" : ""
        },
        "Group" : {
            "Name" : "*"
        },
        "Framework" : {
            "Name" : DEFAULT_DEPLOYMENT_FRAMEWORK,
            "Model" : "passthrough",
            "Scope" : VIEW_MODEL_SCOPE
        }
      },
      "View" : {
          "Name" : BLUEPRINT_VIEW_TYPE
      }
    }
/]

[#if (commandLineOptions.Deployment.Unit.Subset!"") == "generationcontract" ]
  [#assign allDeploymentUnits = false]
[/#if]

[@generateOutput
    deploymentFramework=commandLineOptions.Deployment.Framework.Name
    type=commandLineOptions.Deployment.Output.Type
    format=commandLineOptions.Deployment.Output.Format
/]

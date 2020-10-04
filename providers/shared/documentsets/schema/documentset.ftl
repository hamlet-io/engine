[#ftl]

[#-- override the deployment group to get all deployment groups --]
[@addCommandLineOption
    option={
      "Deployment" : {
        "Framework" : {
            "Name" : DEFAULT_DEPLOYMENT_FRAMEWORK,
            "Model" : "passthrough",
            "Scope" : VIEW_MODEL_SCOPE
        }
      },
      "View" : {
        "Name" : SCHEMA_VIEW_TYPE
      }
    }
/]

[@generateOutput
  deploymentFramework=commandLineOptions.Deployment.Framework.Name
  type=commandLineOptions.Deployment.Output.Type
  format=commandLineOptions.Deployment.Output.Format
/]

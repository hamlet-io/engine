[#ftl]

[#macro shared_entrance_loader ]

  [#-- override the deployment group to get all deployment groups --]
  [@addCommandLineOption
      option={
        "Deployment" : {
          "Framework" : {
              "Name" : DEFAULT_DEPLOYMENT_FRAMEWORK
          }
        },
        "View" : {
          "Name" : LOADER_VIEW_TYPE
        },
        "Flow" : {
          "Names" : [ "views" ]
        }
      }
  /]

  [@generateOutput
    deploymentFramework=commandLineOptions.Deployment.Framework.Name
    type=commandLineOptions.Deployment.Output.Type
    format=commandLineOptions.Deployment.Output.Format
  /]

[/#macro]

[#ftl]

[#macro shared_entrance_unitlist ]

  [#assign allDeploymentUnits = true]

  [#-- override the deployment group to get all deployment groups --]
  [@addCommandLineOption
      option={
        "Deployment" : {
          "Group" : {
            "Name" : "*"
          }
        },
        "Flow" : {
          "Names" : [ "components", "views" ]
        },
        "View" : {
          "Name" : UNITLIST_VIEW_TYPE
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

[/#macro]

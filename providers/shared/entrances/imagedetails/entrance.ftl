[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_imagedetails ]

  [#assign allDeploymentUnits = true]

  [#if getCLODeploymentUnitSubset() == "generationcontract" ]
    [#assign allDeploymentUnits = false]
  [/#if]

  [@generateOutput
      deploymentFramework=getCLODeploymentFramework()
      type=getCLODeploymentOutputType()
      format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_buildblueprint ]

  [@generateOutput
      deploymentFramework=getCLODeploymentFramework()
      type=getCLODeploymentOutputType()
      format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_buildblueprint ]

  [@generateOutput
      deploymentFramework=getDeploymentFramework()
      type=getDeploymentOutputType()
      format=getDeploymentOutputFormat()
  /]

[/#macro]

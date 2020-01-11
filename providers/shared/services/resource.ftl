[#ftl]

[#-- Is a resource part of a deployment unit --]
[#function isPartOfDeploymentUnit resourceId deploymentUnit deploymentUnitSubset]
  [#local resourceObject = getStackOutputObject( (commandLineOptions.Deployment.Provider.Names)[0], resourceId)]
  [#local
    currentDeploymentUnit =
      deploymentUnit +
      deploymentUnitSubset?has_content?then(
        "-" + deploymentUnitSubset?lower_case,
        ""
      )
  ]
  [#return !(resourceObject?has_content &&
    (resourceObject.DeploymentUnit != currentDeploymentUnit))]
[/#function]

[#-- Is a resource part of the current deployment unit --]
[#function isPartOfCurrentDeploymentUnit resourceId]
  [#return
    isPartOfDeploymentUnit(
      resourceId,
      commandLineOptions.Deployment.Unit.Name,
      (ignoreDeploymentUnitSubsetInOutputs!false)?then(
        "",
        commandLineOptions.Deployment.Unit.Subset!""
      )
    )
  ]
[/#function]

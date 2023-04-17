[#ftl]

[#-- Is a resource part of a deployment unit --]
[#function isPartOfDeploymentUnit resourceId deploymentUnit deploymentUnitSubset]
  [#local pointObject = getStatePoint(resourceId)]
  [#local
    currentDeploymentUnit =
      deploymentUnit +
      deploymentUnitSubset?has_content?then(
        "-" + deploymentUnitSubset?lower_case,
        ""
      )
  ]
  [#return !(pointObject.Value?has_content && (pointObject.DeploymentUnit != currentDeploymentUnit))]
[/#function]

[#-- Is a resource part of the current deployment unit --]
[#function isPartOfCurrentDeploymentUnit resourceId]
  [#return
    isPartOfDeploymentUnit(
      resourceId,
      getCLODeploymentUnit(),
      (ignoreDeploymentUnitSubsetInOutputs!false)?then(
        "",
        getCLODeploymentUnitSubset()
      )
    )
  ]
[/#function]


[#function getOccurrenceResourceIds resources ]
    [#local resourceIds = []]

    [#list resources as key,value ]
        [#if value?is_hash && value.Id?? ]
            [#local resourceIds = combineEntities(resourceIds, [ value.Id ], UNIQUE_COMBINE_BEHAVIOUR)]

        [#elseif value?is_hash ]
            [#list value as key, value ]
                [#if value?is_hash ]
                    [#local resourceIds = combineEntities(resourceIds, getOccurrenceResourceIds(value))]
                [#elseif value?is_sequence]
                    [#local resourceids = combineEntities(
                      resourceIds,
                      value?filter(x-> x?is_hash || x?is_sequence)?map(x -> getOccurrenceResourceIds(x))
                    )]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#return resourceIds ]
[/#function]

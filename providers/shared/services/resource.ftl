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

[#function getExistingReference provider resourceId attributeType="" inRegion="" inDeploymentUnit="" inAccount=(accountObject.ProviderId)!""]
    [#local attributeType = (attributeType == REFERENCE_ATTRIBUTE_TYPE)?then(
                                "",
                                attributeType
    )]
    [#return getStackOutput( provider, formatAttributeId(resourceId, attributeType), inDeploymentUnit, inRegion, inAccount) ]
[/#function]

[#--function aws_getReference resourceId attributeType="" inRegion="" --]
[#--function azure_getReference id name="" attributeType=""
    [#if id?is_hash
        && id?keys?seq_contains("Id")
        && id?keys?seq_contains("Name")]
        [#local name = id.Name]
        [#local id = id.Id]
    [/#if] --]
[#function getReference provider resourceId attributeType="" inRegion="" optParams={}]
    [#if !(resourceId?has_content)]
        [#return ""]
    [/#if]
    [#if (resourceId?is_hash) && (resourceId.Ref?has_content)]
        [#return
            {
                "Ref" : value.Ref
            }
        ]
    [/#if]
    [#if ((!(inRegion?has_content)) || (inRegion == region)) &&
        isPartOfCurrentDeploymentUnit(resourceId)]
        [#if attributeType?has_content]
            [#local resourceType = getResourceType(resourceId) ]
            [#local mapping = getOutputMappings(provider, resourceType, attributeType)]
            [#if (mapping.Attribute)?has_content]
                [#local fn = getFirstDefinedDirective([
                        [provider, "getReference"]
                    ])]
                [#return
                    InvokeFunction (
                        fn,
                        resourceId, attributeType, inRegion, optParams
                    )
                ]
            [#elseif !(mapping.UseRef)!false ]
                [#return
                    {
                        "Mapping" : "HamletFatal: Unknown Resource Type",
                        "ResourceId" : resourceId,
                        "ResourceType" : resourceType
                    }
                ]
            [/#if]
        [/#if]
        [#return
            {
                "Ref" : resourceId
            }
        ]
    [/#if]
    [#return
        getExistingReference(
            provider,
            resourceId,
            attributeType,
            inRegion)
    ]
[/#function]


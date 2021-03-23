[#if getCLODeploymentUnit()?contains("iam") ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets="template" /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_IDENTITY_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [#list getReferenceData(SERVICEROLE_REFERENCE_TYPE) as id,serviceRole ]
        [#assign serviceLinkedRoleId = formatAccountServiceLinkedRoleId(id) ]

        [#if deploymentSubsetRequired("iam", true) &&
                (serviceRole.Enabled)!true &&
                isPartOfCurrentDeploymentUnit(serviceLinkedRoleId)]

            [@createServiceLinkedRole
                id=serviceLinkedRoleId
                serviceName=serviceRole.ServiceName
                description=serviceRole.Description
            /]

        [/#if]
    [/#list]
[/#if]

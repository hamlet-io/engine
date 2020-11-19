[#ftl]

[#macro shared_view_default_loader_generationcontract  ]
    [@addDefaultGenerationContract subsets="providercontract" /]
[/#macro]

[#macro shared_view_default_loader_providercontract ]

    [#local providerInstallStageId = formatId("provider", "install" )]
    [@contractStage
        id=providerInstallStageId
        executionMode=CONTRACT_EXECUTION_MODE_PARALLEL
        priority=10
        mandatory=true
    /]

    [#list getActiveProvidersFromLayers() as activeProvider ]

        [@contractStep
            id=activeProvider.Name
            stageId=providerInstallStageId
            taskType=INSTALL_PROVIDER_TASK_TYPE
            parameters=activeProvider
            priority=100
            mandatory=true
        /]
    [/#list]

[/#macro]

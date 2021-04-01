[#ftl]

[#macro shared_view_default_loader_generationcontract  ]
    [@addDefaultGenerationContract subsets="plugincontract" /]
[/#macro]

[#macro shared_view_default_loader_plugincontract ]

    [#local pluginInstallStageId = formatId("plugin", "install" )]
    [@contractStage
        id=pluginInstallStageId
        executionMode=CONTRACT_EXECUTION_MODE_PARALLEL
        priority=10
        mandatory=true
    /]

    [#list getLoader().Plugins as activePlugin ]

        [@contractStep
            id=activePlugin.Id
            stageId=pluginInstallStageId
            taskType=INSTALL_PLUGIN_TASK_TYPE
            parameters=activePlugin
            priority=100
            mandatory=true
        /]
    [/#list]

[/#macro]

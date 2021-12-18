[#ftl]

[#macro shared_view_default_schemalist_generationcontract  ]
    [@addDefaultGenerationContract subsets=["schemacontract"] /]
[/#macro]

[#macro shared_view_default_schemalist_schemacontract ]

    [#local sections = [
        "layer",
        "component",
        "reference",
        "attributeset",
        "module"
    ]]

    [#local stageId = "SchemaList"]

    [@contractStage
        id=stageId
        executionMode=CONTRACT_EXECUTION_MODE_PARALLEL
        priority=10
        mandatory=true
    /]

    [#list getConfigurationScopeIds() as schema ]
        [@contractStep
            id=formatId(schema)
            stageId=stageId
            taskType=CREATE_SCHEMA_TASK_TYPE
            priority=100
            mandatory=false
            parameters=
                {
                    "Schema" : schema
                }
        /]
    [/#list]

[/#macro]

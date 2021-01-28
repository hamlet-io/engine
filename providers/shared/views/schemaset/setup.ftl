[#ftl]

[#macro shared_view_default_schemaset_generationcontract  ]
    [@addDefaultGenerationContract subsets=["schemacontract"] /]
[/#macro]

[#macro shared_view_default_schemaset_schemacontract ]

    [#local sections = ["component", "reference", "attributeset"] ]

    [#list sections as section ]

        [#local stageId=formatId(section)]
        [@contractStage
            id=formatId(section)
            executionMode=CONTRACT_EXECUTION_MODE_PARALLEL
            priority=10
            mandatory=true
        /]

        [#switch section]
            [#case "component" ]
                [@includeAllComponentDefinitionConfiguration
                    SHARED_PROVIDER
                    commandLineOptions.Deployment.Provider.Names
                /]
                [#local schemas = componentConfiguration?keys ]
                [#break]
            [#case "reference" ]
                [#local schemas = referenceConfiguration?keys ]
                [#break]
            [#case "attributeset" ]
                [#local schemas = attributeSetConfiguration?keys ]
                [#break]
        [/#switch]

        [#local outputMappings =
            getGenerationContractStepOutputMapping(SHARED_PROVIDER, "schema")]

        [#if schemas?? ]
            [#list schemas as schema]
                [@contractStep
                    id=formatId(schema)
                    stageId=stageId
                    taskType=CREATE_SCHEMASET_TASK_TYPE
                    priority=100
                    mandatory=true
                    parameters=
                        {
                            "SchemaType" : section,
                            "SchemaInstance" : schema
                        }
                /]
            [/#list]
        [/#if]
    [/#list]
[/#macro]

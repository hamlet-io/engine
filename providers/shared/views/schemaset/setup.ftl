[#ftl]

[#macro shared_view_default_schemaset_generationcontract  ]
    [@addDefaultGenerationContract subsets=["schemacontract"] /]
[/#macro]

[#macro shared_view_default_schemaset_schemacontract ]

    [#local sections = ["component", "reference", "attributeset", "module" ] ]

    [#list sections as section ]

        [#local stageId=formatId(section)]
        [@contractStage
            id=formatId(section)
            executionMode=CONTRACT_EXECUTION_MODE_PARALLEL
            priority=10
            mandatory=false
        /]

        [#switch section]
            [#case "component" ]
                [@includeAllComponentDefinitionConfiguration
                    SHARED_PROVIDER
                    getLoaderProviders()
                /]
                [#local schemas = componentConfiguration?keys ]
                [#break]
            [#case "reference" ]
                [#local schemas = referenceConfiguration?keys ]
                [#break]
            [#case "attributeset" ]
                [#local schemas = attributeSetConfiguration?keys ]
                [#break]
            [#case "module" ]
                [#local schemas = moduleConfiguration?keys ]
                [#break]
        [/#switch]

        [#local outputMappings =
            getGenerationContractStepOutputMapping(
                                combineEntities(
                                    getLoaderProviders(),
                                    [ SHARED_PROVIDER],
                                    UNIQUE_COMBINE_BEHAVIOUR
                                ),
                                "schema" )]

        [#if schemas?? ]
            [#list schemas as schema]
                [@contractStep
                    id=formatId(schema)
                    stageId=stageId
                    taskType=CREATE_SCHEMASET_TASK_TYPE
                    priority=100
                    mandatory=false
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

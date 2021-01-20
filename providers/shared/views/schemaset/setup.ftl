[#ftl]

[#macro shared_view_default_schemaset_generationcontract  ]
    [@addDefaultGenerationContract subsets=["schemacontract"] /]
[/#macro]

[#macro shared_view_default_schemaset_schemacontract ]

    [#local section = commandLineOptions.Deployment.Group.Name]
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
        [#default]
            [@fatal 
                message="Invalid Schema section"
                context=section
            /]
            [#break]
    [/#switch]

    [#local outputMappings = 
        getGenerationContractStepOutputMapping(SHARED_PROVIDER, "schema")]

    [#if schemas?? ]
        [#list schemas as schema]
            [@contractStep
                id=formatId(schema)
                stageId=stageId
                taskType=PROCESS_TEMPLATE_PASS_TASK_TYPE
                priority=100
                mandatory=true
                parameters=
                    {
                        "provider"      : ((commandLineOptions.Deployment.Provider.Names)?join(","))!SHARED_PROVIDER,
                        "framework"     : commandLineOptions.Deployment.Framework.Name,
                        "outputType"    : outputMappings["OutputType"],
                        "outputFormat"  : outputMappings["OutputFormat"],
                        "outputSuffix"  : outputMappings["OutputSuffix"],
                        "subset"        : "schema",
                        "alternative"   : ""
                    }
            /]
        [/#list]
    [/#if]
[/#macro]
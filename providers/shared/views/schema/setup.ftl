[#ftl]

[#macro shared_view_default_schema_generationcontract  ]
    [@addDefaultGenerationContract subsets=["schemacontract"] /]
[/#macro]

[#macro shared_view_default_schema_schemacontract ]

    [#local section = commandLineOptions.Deployment.Unit.Name]
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
                message="Invalid Schema Contract Deployment Unit"
                context=section
            /]
            [#break]
    [/#switch]

    [#local outputMappings = 
        getGenerationContractStepOutputMapping(SHARED_PROVIDER, "schema")]

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
                    "subset"        : schema,
                    "alternative"   : ""
                }
        /]
    [/#list]
[/#macro]

[#macro shared_view_default_schema ]

    [#local section = commandLineOptions.Deployment.Unit.Name]

    [#switch section]

        [#case "component"]

            [@includeAllComponentDefinitionConfiguration
                SHARED_PROVIDER
                commandLineOptions.Deployment.Provider.Names
            /]

            [#list componentConfiguration as id,configuration]
                [#assign schemaComponentAttributes = []]

                [#-- Construct Component Attributes --]
                [#list providerDictionary?keys as provider]

                    [#if (configuration.ResourceGroups["default"].Attributes[provider]!{})?has_content]

                        [#assign schemaComponentAttributes = combineEntities(
                            schemaComponentAttributes,
                            configuration.ResourceGroups["default"].Attributes[provider],
                            ADD_COMBINE_BEHAVIOUR)]

                    [/#if]
                [/#list]

                [#-- Construct SubComponent References as Attributes--]
                [#if (configuration.Components![])?has_content]
                    [#list configuration.Components as subComponent]
                        [#assign schemaComponentAttributes = combineEntities(
                            schemaComponentAttributes,
                            [{
                                "Names" : subComponent.Component,
                                "Ref" : true,
                                "Path" : formatPath(false, "definitions", id)
                            }],
                            ADD_COMBINE_BEHAVIOUR)]

                    [/#list]
                [/#if]

                [@addSchema
                    section="component"
                    subset=id
                    configuration=
                    formatJsonSchemaFromComposite(
                        {
                            "Names" : id,
                            "Type" : OBJECT_TYPE,
                            "SubObjects" : true,
                            "Children" : schemaComponentAttributes
                        },
                        attributeSetConfiguration?keys
                    )
                /]

            [/#list]
            [#break]

        [#case "reference"]

            [#list referenceConfiguration as id,configuration]
                [@addSchema
                    section="reference"
                    subset=configuration.Type.Plural
                    configuration=
                        formatJsonSchemaFromComposite(
                            {
                                "Names" : configuration.Type.Plural,
                                "Type" : OBJECT_TYPE,
                                "SubObjects" : true,
                                "Children" : configuration.Attributes
                            },
                            attributeSetConfiguration?keys)
                /]
            [/#list]
            [#break]

        [#case "attributeset"]

            [#-- Key Value Pairs of AttributeSet Name : Configuration --]
            [#list attributeSetConfiguration as id,configuration]
                [@addSchema
                    section="attributeset"
                    subset=id
                    configuration=
                    formatJsonSchemaFromComposite(
                        {
                            "Names" : id,
                            "Type" : OBJECT_TYPE,
                            "SubObjects" : true,
                            "Children" : configuration.Attributes
                        }
                    )
                /]
            [/#list]
            [#break]

        [#default]
            [#break]

    [/#switch]

    [@addSchemaToDefaultJsonOutput
        section=section
        schemaId=formatSchemaId(section)
        config=getSchema(section)!{}
    /]
[/#macro]

[#ftl]

[#macro shared_view_default_schema_generationcontract  ]
    [@addDefaultGenerationContract subsets=["schema"] /]
[/#macro]

[#macro shared_view_default_schema ]

    [#local section = commandLineOptions.Deployment.Group.Name]
    [#local schema = commandLineOptions.Deployment.Unit.Name]

    [#switch section]

        [#case "component"]

            [@includeAllComponentDefinitionConfiguration
                SHARED_PROVIDER
                commandLineOptions.Deployment.Provider.Names
            /]
            [#local configuration = componentConfiguration[schema] ]

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
                            "Path" : formatPath(false, "definitions", subComponent.Type)
                        }],
                        ADD_COMBINE_BEHAVIOUR)]

                [/#list]
            [/#if]

            [@addSchema
                section="component"
                schema=schema
                configuration=
                formatJsonSchemaFromComposite(
                    {
                        "Names" : schema,
                        "Type" : OBJECT_TYPE,
                        "SubObjects" : true,
                        "Children" : schemaComponentAttributes
                    },
                    attributeSetConfiguration?keys
                )
            /]

            [#break]

        [#case "reference"]

            [#list referenceConfiguration as id,configuration]
                [@addSchema
                    section="reference"
                    schema=configuration.Type.Plural
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
                    schema=id
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
        section=schema
        schemaId=formatSchemaId(section, schema)
        config=getSchema(section)!{}
    /]

[/#macro]
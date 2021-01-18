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
                            "Component" : subComponent.Type
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

            [#-- The CommandLineOption for Schema expects the singular name. --]
            [#-- But the compositeObject structure uses pluralised names as  --]
            [#-- the object ID's. So we check the singular name matches first--]
            [#-- then re-set schema name value to the pluralisation.         --]
            [#list referenceConfiguration as id, configuration]
                [#if configuration.Type.Singular?lower_case == schema]

                    [@addSchema
                        section="reference"
                        schema=configuration.Type.Singular
                        configuration=
                            formatJsonSchemaFromComposite(
                                {
                                    "Names" : configuration.Type.Plural,
                                    "Types" : OBJECT_TYPE,
                                    "SubObjects" : true,
                                    "Children" : configuration.Attributes
                                },
                                attributeSetConfiguration?keys)
                    /]
                [/#if]
            [/#list]
            [#break]

        [#case "attributeset"]

            [#-- Key Value Pairs of AttributeSet Name : Configuration --]
            [#list attributeSetConfiguration as id,configuration]
                [#if configuration.Type.Singular?lower_case == schema]
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
                [/#if]
            [/#list]
            [#break]

        [#default]
            [#break]

    [/#switch]

    [#local schemaOutputConfiguration = getSchema(section)!{}]

    [#if schemaOutputConfiguration?has_content]
        [@addSchemaToDefaultJsonOutput
            section=schema
            schemaId=formatSchemaId(section, schema)
            config=schemaOutputConfiguration
        /]
    [#else]
        [@fatal
            message="Schema instance type not found. Did you mean to try the Singular Name?"
            context={
                "SchemaType" : section,
                "SchemaInstance" : schema
            }
        /]
    [/#if]

[/#macro]
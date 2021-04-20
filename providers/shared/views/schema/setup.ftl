[#ftl]

[#macro shared_view_default_schema_generationcontract  ]
    [@addDefaultGenerationContract subsets=["schema"] /]
[/#macro]

[#macro shared_view_default_schema ]

    [#local section = getCLODeploymentGroup() ]
    [#local schema = getCLODeploymentUnit() ]
    
    [#local schemaCLO = getCommandLineOptions().Schema ]
    [#local schemaId = schemaCLO.Id!formatSchemaId(section, schema) ]
    [#local schemaVersion = schemaCLO.Version ]
    [#if schemaCLO.Prefixed ]
        [#local schemaId = formatSchemaId(section, schema, schemaVersion, schemaIdUrl )]
    [/#if]

    [#switch section]
        [#case "layer" ]

            [#-- Validate layers - we validate them here for a more helpful error --]
            [#if !(layerConfiguration?keys?seq_contains(schema?capitalize))]
                [@fatal
                    message="Invalid layer provided."
                    context={"Layers" : layerConfiguration?keys}
                /]
                [#break]
            [#else]

                [#local schemaLayerConfig =
                    getLayerConfiguration(schema?capitalize)]

                [#local schemaLayerAttributes = schemaLayerConfig.Attributes![]]

                [@addSchema
                    section="layer"
                    schema=schema
                    configuration=
                    formatJsonSchemaFromComposite(
                        {
                            "Names" : schema,
                            "Type" : OBJECT_TYPE,
                            "SubObjects" : true,
                            "Children" : schemaLayerAttributes
                        },
                        attributeSetConfiguration?keys
                    )
                /]

            [/#if]

            [#break]

        [#case "component"]

            [@includeAllComponentDefinitionConfiguration
                SHARED_PROVIDER
                getLoaderProviders()
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

        [#case "module"]
            [#list moduleConfiguration as moduleId, providersConfig]
                [#if moduleId == schema]
                    [#list providersConfig as id, configuration]
                        [@addSchema
                            section="module"
                            schema=moduleId
                            configuration=
                                formatJsonSchemaFromComposite(
                                    {
                                        "Names" : moduleId,
                                        "Types" : OBJECT_TYPE,
                                        "SubObjects" : true,
                                        "Children" : configuration.Properties
                                    },
                                    attributeSetConfiguration?keys)
                        /]
                    [/#list]
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
            config=schemaOutputConfiguration
            schemaId=schemaId
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

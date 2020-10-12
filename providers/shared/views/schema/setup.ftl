[#ftl]

[#macro shared_view_schema_default_generationcontract  ]
    [@addDefaultGenerationContract subsets="schema" /]
[/#macro]

[#macro shared_view_schema_default_schema ]

    [#local section = commandLineOptions.Deployment.Unit.Name]

    [#switch section]

        [#case "component"]

            [@includeAllComponentConfiguration
                SHARED_PROVIDER
                commandLineOptions.Deployment.Provider.Names
            /]

            [#list componentConfiguration as id,configuration]
            [#assign schemaComponentAttributes = []]
            [#list providerDictionary?keys as provider]
                [#if (configuration.ResourceGroups["default"].Attributes[provider]!{})?has_content]

                [#assign schemaComponentAttributes = combineEntities(
                    schemaComponentAttributes,
                    configuration.ResourceGroups["default"].Attributes[provider],
                    ADD_COMBINE_BEHAVIOUR)]

                [/#if]
            [/#list]

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
                    }
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
                        })
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

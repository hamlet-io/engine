[#ftl]

[#macro shared_view_default_schema_generationcontract  ]
    [@addDefaultGenerationContract subsets="schema" /]
[/#macro]

[#macro shared_view_default_schema ]

    [#local section = commandLineOptions.Deployment.Unit.Name]

    [#switch section]

        [#case "component"]

            [#-- Attribute names that should be turned into refs --]
            [#local createRefValues = ["Links"]]

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
                        createRefValues
                    )
                /]

            [/#list]
            [#break]

        [#case "reference"]

            [#-- Attribute names that should be turned into refs --]
            [#local createRefValues = ["Links"]]

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
                            metaparameters)
                /]
            [/#list]
            [#break]

        [#case "metaparameter"]

            [#local createRefValues = []]

            [#-- Key Value Pairs of Metaparameter Name : Configuration --]
            [#list metaparameterConfiguration as id,configuration]
                [@addSchema
                    section="metaparameter"
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

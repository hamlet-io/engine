[#ftl]

[#macro shared_view_default_schema_generationcontract  ]

    [#local schemaPattern = (getCommandLineOptions().Schema)!""]

    [@addDefaultGenerationContract
        subsets=["schema"]
        alternatives=getConfigurationScopeIds()?filter( x -> x?matches(schemaPattern, "is"))
        contractCleanup=false
    /]
[/#macro]

[#macro shared_view_default_schema ]

    [#local configurationScope = getCLODeploymentUnitAlternative()]

    [@jsonSchema
        id=formatSchemaId(configurationScope)
        schema="http://json-schema.org/draft-07/schema#"
    /]

    [#local schemaDefinitions = {}]

    [#switch configurationScope]
        [#case COMPONENT_CONFIGURATION_SCOPE]
            [#list getAllComponentConfiguration() as componentType, componentDefinition ]

                [#local schemaComponentAttributes = []]

                [#-- Construct Component Attributes --]
                [#list getComponentResourceGroups(componentType) as id, resourceGroup ]

                    [#list getLoaderProviders() as provider ]

                        [#local schemaComponentAttributes = combineEntities(
                                    schemaComponentAttributes,
                                    getComponentResourceGroupAttributes(resourceGroup, provider),
                                    ADD_COMBINE_BEHAVIOUR
                                )]
                    [/#list]
                [/#list]

                [#-- Construct SubComponent References as Attributes--]
                [#list (getComponentChildren(componentType))![] as subComponent]
                    [#local schemaComponentAttributes = combineEntities(
                        schemaComponentAttributes,
                        [{
                            "Names" : [ subComponent.Component ],
                            "Component" : subComponent.Type
                        }],
                        ADD_COMBINE_BEHAVIOUR)]

                [/#list]

                [#local schemaDefinitions = mergeObjects(
                    schemaDefinitions,
                    {
                        componentType : {
                            "Attributes" : schemaComponentAttributes,
                            "Description" : (((componentDefinition.Properties)![])?filter( x -> x.Type == "Description")[0].Value)!""
                        }
                    }
                )]

            [/#list]
            [#break]

        [#default]
            [#list getConfigurationSets(configurationScope) as configurationSet ]
                [#if ((configurationSet.Attributes)![])?has_content ]
                    [#local schemaDefinitions = mergeObjects(
                        schemaDefinitions,
                        {
                            configurationSet.Id : {
                                "Attributes" : configurationSet.Attributes,
                                "Description" : (((configurationSet.Properties)![])?filter( x -> x.Type == "Description")[0].Value)!""
                            }
                        })]
                [/#if]
            [/#list]
            [#break]
    [/#switch]

    [#list schemaDefinitions as id, definition ]
        [@jsonSchemaDefinition
            id=id
            schema=
                jsonSchemaDocument(
                    "",
                    "",
                    mergeObjects(
                        {
                            "description" : definition.Description
                        },
                        convertAttributesToJsonSchemaProperties(
                            compressCompositeConfiguration(
                                normaliseCompositeConfiguration(
                                    definition.Attributes
                                )
                            )
                        )
                    ),
                    {},
                    "object"
                )
        /]
    [/#list]
[/#macro]


[#-- Suppport Macros --]
[#assign schemaHostSite = "https://docs.hamlet.io"]
[#assign rootSchemaPath = formatPath(false, schemaHostSite, "schema")]

[#assign patternPropertiesRegex = r'^[A-Za-z_][A-Za-z0-9_-]*$']

[#-- Document formatting --]
[#function formatSchemaId schema definition="" version="latest"]
    [#return formatPath(false, rootSchemaPath, version, "${schema}-schema.json" + definition?has_content?then("#/definitions/${definition}", "")) ]
[/#function]

[#function convertAttributesToJsonSchemaProperties attributes ]
    [#local result = {}]
    [#local required = []]

    [#list asFlattenedArray(attributes) as attribute]

        [#if ! attribute?is_hash ]
            [#continue]
        [/#if]

        [#local properties = {}]

        [#-- Required Properties --]
        [#if attribute.Mandatory ]
            [#local required = combineEntities(required, attribute.Names?first, UNIQUE_COMBINE_BEHAVIOUR) ]
        [/#if]

        [#-- Description --]
        [#if attribute.Description?has_content ]
            [#local properties += { "description" : attribute.Description }]
        [/#if]

        [#-- Default --]
        [#if attribute.Default?has_content ]
            [#local properties += { "default" : attribute.Default }]
        [/#if]

        [#-- Determine Properties --]
        [#local typeResult = []]
        [#if attribute.Children?has_content ]
            [#local typeResult = [ "object" ]]
            [#local properties += { "additionalProperties" : false }]

        [#elseif attribute.AttributeSet?has_content || attribute.Component?has_content ]

        [#-- Don't include type details on refs --]
        [#elseif attribute.Types?seq_contains(ANY_TYPE)]
            [#local typeResult = [ "array", "boolean", "number", "object", "string" ]]

        [#-- Handle a standalone ARRAY_OF_TYPE type --]
        [#elseif attribute.Types?is_sequence && attribute.Types?size == 2 && attribute.Types?first == ARRAY_TYPE ]
            [#local typeResult = combineEntities(typeResult, [ "array" ], UNIQUE_COMBINE_BEHAVIOUR)]
            [#local properties = mergeObjects(
                properties,
                {
                    "contains" : {
                        "type" : combineEntities((properties["contains"]["type"])![], [ attribute.Types?last ], UNIQUE_COMBINE_BEHAVIOUR )
                    }
                }
            )]

        [#else]
            [#list attribute.Types as type ]
                [#if type?is_string]
                    [#switch type]
                        [#case NUMBER_TYPE]
                        [#case STRING_TYPE]
                        [#case BOOLEAN_TYPE]
                        [#case OBJECT_TYPE]
                        [#case ARRAY_TYPE]
                            [#local typeResult += [ type ]]
                            [#break]
                        [#default]
                            [#local typeResult += [ "string"]]
                    [/#switch]

                [#-- Handle an ARRAY_OF_TYPE as part of a collection of types --]
                [#elseif type?is_sequence && type?size == 2 && type?first == ARRAY_TYPE ]
                    [#local typeResult = combineEntities(typeResult, [ "array" ], UNIQUE_COMBINE_BEHAVIOUR)]
                    [#local properties = mergeObjects(
                        properties,
                        {
                            "contains" : {
                                "type" : combineEntities((properties["contains"]["type"])![], [ type?last ], UNIQUE_COMBINE_BEHAVIOUR )
                            }
                        }
                    )]
                [/#if]
            [/#list]
        [/#if]

        [#if ((properties["contains"]["type"])![])?size == 1 ]
            [#local properties = mergeObjects(
                properties,
                {
                    "contains" : {
                        "type" : (properties["contains"]["type"])?first
                    }
                }
            )]
        [/#if]

        [#if typeResult?size == 1 ]
            [#local properties += { "type" : typeResult?first }]
        [#elseif typeResult?size > 1 ]
            [#local properties += { "type" : typeResult }]
        [/#if]

        [#-- Allowed Values --]
        [#if attribute.Values?has_content ]
            [#if asArray(attribute.Values)?size == 1 ]
                [#local properties += { "const" : attribute.Values?first }]
            [#else]
                [#local properties += { "enum" : attribute.Values }]
            [/#if]
        [/#if]

        [#-- Children Handling --]
        [#if attribute.Children?has_content ]
            [#local childDetails = convertAttributesToJsonSchemaProperties(attribute.Children) ]

            [#if attribute.SubObjects ]
                [#local properties +=
                    {
                        "patternProperties" : {
                            patternPropertiesRegex : childDetails
                        }
                    }]
            [#else]
                [#local properties +=  childDetails]
            [/#if]
        [/#if]

        [#-- External Schema references --]
        [#if attribute.AttributeSet?has_content ]
            [#local properties += {
                "$ref" : formatSchemaId("AttributeSet", attribute.AttributeSet)
            }]
        [/#if]

        [#if attribute.Component?has_content ]
            [#local properties += {
                "$ref" : formatSchemaId("Component", attribute.Component)
            }]
        [/#if]

        [#local result = mergeObjects(
            result,
            {
                "properties" : {
                    (attribute.Names)?first : properties
                }
            })]

    [/#list]

    [#if required?has_content ]
        [#local result += { "required" : required }]
    [/#if]

    [#return result]
[/#function]

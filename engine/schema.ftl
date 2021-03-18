[#ftl]

[#assign HamletSchemas = {
    "Root" : "http://json-schema.org/draft-07/schema#"
}]
[#assign schemaHostSite = "https://docs.hamlet.io"]
[#assign rootSchemaPath = formatPath(false, schemaHostSite, "schema")]

[#assign patternPropertiesRegex = r'^[A-Za-z_][A-Za-z0-9_]*$']
[#assign schemaConfiguration = {}]

[#macro addSchema section schema configuration]
    [@internalMergeSchemaConfiguration
        section=section
        schema=schema
        configuration=configuration
    /]
[/#macro]

[#function getSchema section=""]
    [#if section??]
        [#return schemaConfiguration[section]]
    [/#if]
    [#return schemaConfiguration]
[/#function]

[#function formatJsonSchemaAdditionalProperties composite]
    [#if hasSubObjects(composite)
        || ! composite.Children??]
        [#return {}]
    [#else]
        [#return false]
    [/#if]
[/#function]

[#-- support for multiple types through "anyOf" --]
[#function formatJsonSchemaBaseType composite id=""]
    [#local optionSets = []]
    [#local result = {}]
    [#if composite.Types?has_content]
        [#if composite.Types?is_sequence]
            [#if composite.Types?first == ARRAY_TYPE]
                [#-- Define an "array" of X type --]
                [#switch composite.Types?last]
                    [#case ANY_TYPE]
                        [#local result += {
                            "type" : ARRAY_TYPE }]
                        [#break]
                    [#default]
                        [#local result += {
                            "type" : ARRAY_TYPE,
                            "contains" : {
                                "type" : composite.Types?last }}]
                        [#break]
                [/#switch]
            [#else]
                [#local optionSets += composite.Types?map(t -> { "type" : t })]
            [/#if]
        [#else]
            [#local result += { "type" : composite.Types }]
        [/#if]
    [#elseif composite.Component?? || composite.AttributeSet??]
        [#local result += formatJsonSchemaReference(composite)]
    [#else]
        [#local result += { "type" : OBJECT_TYPE }]
    [/#if]
    [#return result +
        attributeIfContent("$id", id) +
        attributeIfContent("additionalProperties", formatJsonSchemaAdditionalProperties(composite)) +
        attributeIfContent("anyOf", optionSets)]
[/#function]

[#function hasSubObjects composite]
    [#-- Subobjects is inconsistently capitalised making it a difficult object key --]
    [#local subObjectsIndex = composite
        ?keys?map(k -> k?lower_case)?seq_index_of("subobjects")]
    [#return (subObjectsIndex >= 0)
        ?then(composite?values[subObjectsIndex], false)]
[/#function]

[#function formatJsonSchemaBaseName composite]
    [#return asArray(composite.Names)[0]]
[/#function]

[#function formatSchemaId section unit version="latest"]
    [#switch section]
        [#default]
            [#return formatPath(false, rootSchemaPath, version, "blueprint", "schema-" + section + "-" + unit + "-schema.json")]
            [#break]
    [/#switch]
[/#function]

[#function formatJsonSchemaFromComposite composite references=[] schemaId=""]
    [#local jsonSchema = {}]
    [#local required = []]
    [#local childrenConfiguration = {}]

    [#if composite?is_hash]
        [#local schemaName = formatJsonSchemaBaseName(composite)]
        [#if !references?seq_contains(schemaName)]
            [#if schemaId?has_content]
                [#local section = getDeploymentUnit()]
                [#local schemaId = formatPath(false, schemaId?remove_ending(".json"), section + ".json")]
            [/#if]

            [#local subObjects = hasSubObjects(composite)]

            [#local jsonSchema = mergeObjects(
                jsonSchema,
                formatJsonSchemaBaseType(composite),
                attributeIfContent("description", composite.Description!""),
                attributeIfTrue("default", composite.Default?has_content, composite.Default!false),
                attributeIfContent("enum", composite.Values![]))]

            [#if composite.Children?has_content]

                [#-- required --]
                [#local required = composite.Children
                    ?filter(c -> c?is_hash && c.Mandatory!false)
                    ?map(c -> formatJsonSchemaBaseName(c))]

                [#list composite.Children as child]

                    [#if child?is_hash]

                        [#local childSchemaName = formatJsonSchemaBaseName(child)]
                        [#if !references?seq_contains(childSchemaName)]
                            [#local childrenConfiguration = mergeObjects(
                                childrenConfiguration,
                                subObjects?then(
                                    {
                                        "patternProperties" : {
                                            patternPropertiesRegex : {
                                                "properties" : {
                                                    childSchemaName : formatJsonSchemaFromComposite(child, references)
                                                },
                                                "additionalProperties" : false
                                            } +
                                            attributeIfContent("required", required)
                                        }
                                    },
                                    {
                                        "properties" : {
                                            childSchemaName : formatJsonSchemaFromComposite(child, references)
                                        },
                                        "additionalProperties" : false
                                    } +
                                    attributeIfContent("required", required)
                                )
                            )]
                        [#else]
                            [#-- Create a Reference to schema --]
                            [#local childrenConfiguration = mergeObjects(
                                childrenConfiguration,
                                subObjects?then(
                                    {
                                        "patternProperties" : {
                                            patternPropertiesRegex : {
                                                "properties" : {
                                                    childSchemaName : formatJsonSchemaFromComposite(
                                                        {
                                                            "Names" : childSchemaName,
                                                            "AttributeSet" : childSchemaName
                                                        }
                                                    )
                                                }
                                            }
                                        }
                                    },
                                    {
                                        "properties" : {
                                            childSchemaName : formatJsonSchemaFromComposite(
                                                {
                                                    "Names" : childSchemaName,
                                                    "AttributeSet" : childSchemaName
                                                }
                                            )
                                        }
                                    }
                                )
                            )]
                        [/#if]
                    [#else]
                        [@debug
                            message="Found child composite of unknown structure: "
                            context={ "Child" : child, "Parent" : composite }
                            enabled=false
                        /]
                    [/#if]
                [/#list]
            [/#if]

            [#if childrenConfiguration?has_content]
                [#local jsonSchema =
                    mergeObjects(
                        jsonSchema,
                        childrenConfiguration
                    )]
            [/#if]
        [#else]
            [#local jsonSchema =
                mergeObjects(
                    jsonSchema,
                    {
                        schemaName :
                            formatJsonSchemaFromComposite(
                                {
                                    "Names" : schemaName,
                                    "AttributeSet" : schemaName
                                }
                            )
                    }
                )]
        [/#if]
    [#else]
        [@debug
            message="Found composite of unknown structure: "
            context={ "Composite" : composite }
            enabled=false
        /]
    [/#if]
    [#return jsonSchema ]
[/#function]

[#function formatJsonSchemaReference composite]
    [#if composite.AttributeSet??]
        [#local section = "attributeset"]
        [#local unit = composite.AttributeSet]
    [#elseif composite.Component??]
        [#local section = "component"]
        [#local unit = composite.Component]
    [/#if]
    [#if section?has_content && unit?has_content]
        [#return { "$ref" : formatSchemaId(section, unit) }]
    [/#if]
    [@fatal message="Invalid Reference" context={"comp" : composite, "conf" : configuration} /]
[/#function]

[#-------------------------------------------------------
-- Internal support functions for schema processing    --
---------------------------------------------------------]

[#macro internalMergeSchemaConfiguration section schema configuration]
    [#assign schemaConfiguration =
        mergeObjects(
            schemaConfiguration,
            {
                section : {
                    schema : configuration
                }
            })]
[/#macro]
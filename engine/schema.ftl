[#ftl]

[#assign HamletSchemas = {
    "Root" : "http://json-schema.org/draft-07/schema#"
}]

[#assign rootSchemaPath = "https://hamlet.io/schema"]
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
    [#local type = composite.Type!composite.Types!""]
    [#if type?has_content]
        [#if type?is_sequence]
            [#if type?first == ARRAY_TYPE]
                [#-- Define an "array" of X type --]
                [#switch type?last]
                    [#case ANY_TYPE]
                        [#local result += { 
                            "type" : ARRAY_TYPE }]
                        [#break]
                    [#default]
                        [#local result += { 
                            "type" : ARRAY_TYPE,
                            "contains" : {
                                "type" : type?last }}]
                        [#break]
                [/#switch]
            [#else]
                [#local optionSets += type?map(t -> { "type" : t })]
            [/#if]
        [#else]
            [#local result += { "type" : type }]
        [/#if]
    [#elseif composite.Ref!false]
        [#if composite.Names == "Links"]
            [#local result += formatJsonSchemaReference(composite.Path, "attributeset")]
        [#else]
            [#local result += formatJsonSchemaReference(composite.Path)]
        [/#if]
    [#elseif composite.Children?? || composite.Subobjects?? ]
        [#local result += { "type" : OBJECT_TYPE }]
    [#else]
        [@fatal 
            message="Missing Data Type on Composite Object"
            context=composite
        /]
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
            [#return formatPath(false, rootSchemaPath, version, "blueprint", section + "-" + unit + "-schema.json")]
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
                [#local section = commandLineOptions.Deployment.Unit.Name]
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
                                                            "Ref" : true,
                                                            "Path" : formatPath(false, "definitions", childSchemaName)
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
                                                    "Ref" : true,
                                                    "Path" : formatPath(false, "#definitions", childSchemaName)
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
                                    "Ref" : true,
                                    "Path" : formatPath(false, "#definitions", schemaName)
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

[#function formatJsonSchemaReference path schema=""]
    [#if schema?has_content]
        [#-- return ref to specified schema --]
        [#return { r"$ref": concatenate(["schema-", schema?lower_case, "-schema.json", path?ensure_starts_with("#/")], '') }]
    [#else]
        [#-- return ref to schema path in same file --]
        [#return { r"$ref": path?ensure_starts_with("#/") }]
    [/#if]
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
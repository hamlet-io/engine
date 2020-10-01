[#ftl]

[#assign HamletSchemas = {
    "Root" : "http://json-schema.org/draft-07/schema#"
}]
[#assign metaparameters = [
    "Links"
]]
[#assign rootSchemaPath = "https://hamlet.io/schema"]
[#assign patternPropertiesRegex = r'^[A-Za-z_][A-Za-z0-9_]*$']
[#assign schemaConfiguration = {}]

[#macro addSchema section subset configuration]
    [@internalMergeSchemaConfiguration
        section=section
        subset=subset
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
    [#if composite.Type?has_content]
        [#if composite.Type?is_sequence]
            [#if composite.Type?first == ARRAY_TYPE]
                [#-- Define an "array" of X type --]
                [#switch composite.Type?last]
                    [#case ANY_TYPE]
                        [#local result += { 
                            "type" : ARRAY_TYPE }]
                        [#break]
                    [#default]
                        [#local result += { 
                            "type" : ARRAY_TYPE,
                            "contains" : {
                                "type" : composite.Type?last }}]
                        [#break]
                [/#switch]
            [#else]
                [#local optionSets += composite.Type?map(t -> [{ "type" : t }])]
            [/#if]
        [#elseif composite.Type == REF_TYPE]
            [#local result += formatJsonSchemaReference(composite.Path, composite.File)]
        [#else]
            [#local result += { "type" : composite.Type }]
        [/#if]
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

[#function formatSchemaId section version="latest"]
    [#switch section]
        [#default]
            [#return formatPath(false, rootSchemaPath, version, "blueprint", section + "-schema.json")]
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
                                                            "Type" : REF_TYPE,
                                                            "File" : "metaparameter-schema.json",
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
                                                    "Type" : REF_TYPE,
                                                    "File" : "metaparameter-schema.json",
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
                                    "Type" : REF_TYPE,
                                    "File" : "metaparameter-schema.json",
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

[#function formatJsonSchemaReference path file=""]
    [#return { r"$ref": concatenate([file, path?ensure_starts_with("#/")], '') }]
[/#function]

[#-------------------------------------------------------
-- Internal support functions for schema processing    --
---------------------------------------------------------]

[#macro internalMergeSchemaConfiguration section subset configuration]
    [#assign schemaConfiguration =
        mergeObjects(
            schemaConfiguration,
            {
                section : {
                    subset : configuration
                }
            })]
[/#macro]
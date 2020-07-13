[#ftl]

[#assign schemaConfiguration = {}]

[#macro addSchema scope type properties attributes]
    [@internalMergeSchemaConfiguration
        scope=scope
        type=type
        configuration=
            {
                "Properties" : properties,
                "Attributes" : attributes
            }
    /]
[/#macro]

[#function getSchema type value id="" isRoot=false]

    [#local schema = { "type" : type }]
    [#local requiredProperties = []]
    [#local dependencies = {}]

    [#switch type]
        [#case ARRAY_TYPE]
            [#local properties = mergeObjects(
                properties,
                value?map(v -> getSchema(type, v)))]
            [#break]
        [#case OBJECT_TYPE]

            [#list ["definitions", "properties", "patternProperties"] as section]
                [#list value[section] as child]
                    [#local schema = mergeObjects(
                        schema,
                        getSchema(type, child))]
                [/#list]
            [/#list]

            [#break]
        [#default]
            [#break]
    [/#switch]

    [#return schema
        + attributeIfContent("$id", id)
        + attributeIfTrue("$schema", isRoot, rootSchemaPath)
        + attributeIfContent("definitions", definitions)
        + attributeIfContent("properties", properties)
        + attributeIfContent("patternProperties", patternProperties)
        + attributeIfContent("required", requiredProperties)
        + attributeIfContent("dependencies", dependencies)]
[/#function]

[#-------------------------------------------------------
-- Internal support functions for schema processing    --
---------------------------------------------------------]

[#macro internalMergeSchemaConfiguration scope type configuration]
    [#assign schemaConfiguration =
        mergeObjects(
            schemaConfiguration,
            {
                scope : {
                    type : configuration
                }
            })]
[/#macro]
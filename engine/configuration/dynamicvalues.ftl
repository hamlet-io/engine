[#ftl]

[#assign DYNAMIC_VALUE_CONFIGURATION_SCOPE = "DynamicValue" ]

[@addConfigurationScope
    id=DYNAMIC_VALUE_CONFIGURATION_SCOPE
    description="Configuration of Dynamic Value providers"
/]

[#macro addDynamicValueProvider type parameterOrder parameterAttributes properties=[]]

    [@addConfigurationSet
        scopeId=DYNAMIC_VALUE_CONFIGURATION_SCOPE
        id=type
        properties=properties
        attributes=[
            {
                "Names" : "ParameterOrder",
                "Description" : "The order that the parameters are set in the substitution value",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : combineEntities(["type"], parameterOrder, APPEND_COMBINE_BEHAVIOUR)
            },
            {
                "Names": "Parameters",
                "Description": "The parameters in the dynamic value used for the provider",
                "Children": combineEntities(
                    [
                        {
                            "Names" : "type",
                            "Description" : "The type of the provider",
                            "Types" : STRING_TYPE,
                            "Default" : type,
                            "Values" : [ type ]
                        }
                    ],
                    parameterAttributes,
                    APPEND_COMBINE_BEHAVIOUR
                )
            }
        ]
    /]
[/#macro]


[#function getDynamicValueProvider type ]
    [#local config = getConfigurationSet(DYNAMIC_VALUE_CONFIGURATION_SCOPE, type) ]
    [#if config?has_content ]
        [#return config ]
    [#else]
        [@debug
            message="Could not find dynamic provider configuration"
            detail={"type": type, "Available": getConfigurationSets(DYNAMIC_VALUE_CONFIGURATION_SCOPE) }
            enabled=false
        /]
        [#return {} ]
    [/#if]
[/#function]


[#function getDynamicValue value sources={} ]

    [#if ( value?is_string && ! value?matches(r'.*__[\w:]+?__.*')?has_content ) || ! value?is_string ]
        [#return value ]
    [/#if]

    [#local replacements = {}]
    [#local substitutions = value?matches(r'(__[\w:]+?__)')]

    [#list substitutions as substitution ]
        [#local lookups = substitution?keep_after("__")?keep_before_last("__")?split(":") ]
        [#local type = lookups[0] ]

        [#local dynamicValueProvider = getDynamicValueProvider(type)]

        [#if dynamicValueProvider?has_content ]
            [#local parameterOrder = (dynamicValueProvider.Attributes?filter(x -> asArray(x.Names)?seq_contains("ParameterOrder"))[0]).Default ]

            [#local parameters = {}]

            [#list parameterOrder as param ]
                [#if param?has_content && (lookups[param?index])?has_content ]
                    [#local parameters = mergeObjects(parameters, { param: lookups[param?index]})]
                [/#if]
            [/#list]

            [#local attributeValues = getCompositeObject(
                dynamicValueProvider.Attributes,
                {
                    "Parameters" : parameters
                }
            )]

            [#list combineEntities(getLoaderProviders(), [ SHARED_PROVIDER], UNIQUE_COMBINE_BEHAVIOUR) as provider ]

                [#local functionOptions =
                    [
                        [provider, "dynamicvalue", type ]
                    ]]

                [#local function = getFirstDefinedDirective(functionOptions)]
                [#if function?has_content]
                    [#local replacements =  mergeObjects(
                        replacements,
                        { substitution : (.vars[function](substitution, attributeValues.Parameters, sources))!substitution }
                    )]
                [#else]
                    [@debug
                        message="Unable to invoke any of the function options"
                        context=macroOptions
                        enabled=false
                    /]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#list replacements as original, new ]
        [#if new?is_string]
            [#local value = value?replace(original, new)]
        [#elseif new?is_number || new?is_boolean ]
            [#local value = value?replace(original, new?c)]
        [#elseif (new?is_hash || new?is_sequence) && value == original]
            [#local value = new]
        [#else]
            [@fatal
                message="Invalid dynamic value replacement"
                detail="The dynamic value should either be a string, number, boolean or completely replace the value with an object"
                context={
                    "Value": value,
                    "DynamicValue" : original,
                    "SubstituedValue": new
                }
            /]
        [/#if]
    [/#list]

    [#return value]
[/#function]


[#-- Resolve all Dynamic Values in a given value --]
[#function resolveDynamicValues value sources={} ]
    [#local result = {}]
    [#if value?is_hash ]
        [#list value as k,v ]
            [#local result = mergeObjects(result, { k: resolveDynamicValues(v, sources)})]
        [/#list]

    [#elseif value?is_sequence]
        [#local result = []]
        [#list value as v]
            [#local result = combineEntities(result, resolveDynamicValues(v, sources), APPEND_COMBINE_BEHAVIOUR)]
        [/#list]

    [#elseif value?is_string]
        [#return getDynamicValue(value, sources)]

    [#else]
        [#return value]
    [/#if]

    [#return result]
[/#function]

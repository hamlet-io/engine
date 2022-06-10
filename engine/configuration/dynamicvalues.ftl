[#ftl]

[#assign DYNAMIC_VALUE_CONFIGURATION_SCOPE = "DyanmicValues" ]

[@addConfigurationScope
    id=DYNAMIC_VALUE_CONFIGURATION_SCOPE
    description="Configuration of Dynamic Value providers"
/]

[#macro addDynamicValueProvider type parameterOrder parameterAttributes supportedComponentTypes=["*"] properties=[]]

    [@addConfigurationSet
        scopeId=DYNAMIC_VALUE_CONFIGURATION_SCOPE
        id=type
        properties=properties
        attributes=[
            {
                "Names": "ComponentType",
                "Description": "The supported component types for this dynamic value provider"
            } +
            ( ! supportedComponentTypes?seq_contains("*"))?then(
                {
                    "Values": supportedComponentTypes
                },
                {}
            ),
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


[#function getDynamicValue occurrence value extraSources={} ]

    [#if ( value?is_string && ! value?contains("__") ) || ! value?is_string ]
        [#return value ]
    [/#if]

    [#local substitutions = value?split("__")?filter(x -> x?matches('^[a-zA-Z0-9_-]*:.*'))]
    [#local replacements = {}]

    [#list substitutions as substitution ]
        [#local lookups = substitution?split(":") ]
        [#local type = lookups[0] ]

        [#local dynamicValueProvider = getDynamicValueProvider(type)]

        [#if dynamicValueProvider?has_content ]
            [#local parameterOrder = (dynamicValueProvider.Attributes?filter(x -> asArray(x.Names)?seq_contains("ParameterOrder"))[0]).Default ]

            [#local parameters = {}]

            [#list parameterOrder as param ]
                [#if param?has_content]
                    [#local parameters = mergeObjects(parameters, { param: lookups[param?index]})]
                [/#if]
            [/#list]

            [#local attributeValues = getCompositeObject(
                dynamicValueProvider.Attributes,
                {
                    "ComponentType": occurrence.Core.Type,
                    "Parameters" : parameters
                }
            )]

            [#local substitutionValue = parameterOrder?map( x -> attributeValues.Parameters[x])?join(":") ]

            [#list (occurrence.State.ResourceGroups)?values as resourceGroup ]

                [#local placement = (resourceGroup.Placement)!{} ]
                [#if placement?has_content ]
                    [#local functionOptions =
                        [
                            [placement.Provider, "dynamicvalue", type, placement.DeploymentFramework],
                            [placement.Provider, "dynamicvalue", type ],
                            [SHARED_PROVIDER, "dynamicvalue", type, placement.DeploymentFramework],
                            [SHARED_PROVIDER, "dynamicvalue", type ]
                        ]]

                    [#local function = getFirstDefinedDirective(functionOptions)]
                    [#if function?has_content]
                        [#local replacements =  mergeObjects(
                            replacements,
                            { substitution : .vars[function](substitution, attributeValues.Parameters, occurrence, extraSources) }
                        )]
                    [#else]
                        [@debug
                            message="Unable to invoke any of the function options"
                            context=macroOptions
                            enabled=false
                        /]
                    [/#if]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#list replacements as original, new ]
        [#local value = value?replace("__${original}__", new)]
    [/#list]

    [#return value]
[/#function]


[#-- Resolve all Dynamic Values in a given value --]
[#function resolveDynamicValues occurrence value extraSources={} ]
    [#local result = {}]
    [#if value?is_hash ]
        [#list value as k,v ]
            [#local result = mergeObjects(result, { k: resolveDynamicValues(occurrence, v, extraSources)})]
        [/#list]

    [#elseif value?is_sequence]
        [#local result = []]
        [#list value as v]
            [#local result = combineEntities(result, resolveDynamicValues(occurrence, v extraSources))]
        [/#list]

    [#elseif value?is_string]
        [#return getDynamicValue(occurrence, value, extraSources)]

    [#else]
        [#return value]
    [/#if]

    [#return result]
[/#function]

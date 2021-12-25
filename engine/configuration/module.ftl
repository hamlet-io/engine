[#ftl]

[#-- modules allow loading input data using the engine itself --]
[#assign MODULE_CONFIGURATION_SCOPE = "Module" ]

[@addConfigurationScope
    id=MODULE_CONFIGURATION_SCOPE
    description="Modules extend input data using a code based approach"
/]

[#-- Adds module configuration definition which we use to validate modules loaded via blueprint --]
[#macro addModule name description provider properties=[] ]

    [@addConfigurationSet
        scopeId=MODULE_CONFIGURATION_SCOPE
        id=name
        properties=[
            {
                "Type" : "Description",
                "Value" : description
            }
        ]
        configuration={
            "Provider" : provider
        }
        attributes=properties
    /]
[/#macro]

[#function getModuleConfiguration name="" ]
    [#if name?has_content ]
        [#return getConfigurationSet(MODULE_CONFIGURATION_SCOPE, name)]
    [#else]
        [#local result = {}]
            [#list getConfigurationSets(MODULE_CONFIGURATION_SCOPE) as set]
                [#local result = mergeObjects(result, { set.Id : { "Attributes" : set.Attributes, "Properties" : set.Properties, "Configuration" : set.Configuration }} )]
            [/#list]
        [#return result]
    [/#if]
[/#function]

[#function getModuleDetails name provider parameters ]
    [#local moduleConfig = getModuleConfiguration(name) ]

    [#if ! moduleConfig?has_content ]
        [#return {}]
    [/#if]

    [#local validatedParameters = getCompositeObject(moduleConfig.Attributes, parameters)]
    [#return
        {
            "Name" : name,
            "Provider" : provider,
            "Parameters" : validatedParameters
        }
    ]
[/#function]

[#function getActiveModulesFromLayers layersState ]

    [#local modules = [] ]
    [#list asFlattenedArray(getActiveLayerAttributes( [ "Modules" ], ["*"], [], layersState )) as moduleInstance ]
        [#list moduleInstance?values as module ]
            [#if (module.Enabled)!false]
                [#local modules += [ module ] ]
            [/#if]
        [/#list]
    [/#list]
    [#return modules ]
[/#function]

[#-- Loads the module data into the input data      --]
[#-- Note that a module may choose to call this     --]
[#-- macro multiple times so we need to ensure      --]
[#-- any pre-existing moduleInputState is preserved --]
[#-- For state, the order to the calls should be    --]
[#-- Highest priority first given the way output    --]
[#-- searching is performed                         --]
[#macro loadModule
    blueprint={}
    settingSets=[]
    stackOutputs=[]
    commandLineOption={}
    definitions={} ]

    [#-- Normalise settings --]
    [#local formattedModuleSettings = {} ]
    [#list settingSets as settingSet ]
        [#local formattedModuleSettings =
            mergeObjects(
                formattedModuleSettings,
                formatSettingsEntry(
                    settingSet.Type!"Settings"
                    settingSet.Scope!"Products"
                    settingSet.Settings!{}
                    settingSet.Namespace
                )
            )
        ]
    [/#list]

    [#-- attributeIfContent() returns an empty object if no content --]
    [#assign moduleInputState =
        attributeIfContent(
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            mergeObjects(
                (moduleInputState[COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS])!{},
                commandLineOption
            )
        ) +
        attributeIfContent(
            BLUEPRINT_CONFIG_INPUT_CLASS,
            mergeObjects(
                (moduleInputState[BLUEPRINT_CONFIG_INPUT_CLASS])!{},
                blueprint
            )
        ) +
        attributeIfContent(
            SETTINGS_CONFIG_INPUT_CLASS,
            mergeObjects(
                (moduleInputState[SETTINGS_CONFIG_INPUT_CLASS])!{},
                formattedModuleSettings
            )
        ) +
        attributeIfContent(
            DEFINITIONS_CONFIG_INPUT_CLASS,
            mergeObjects(
                (moduleInputState[DEFINITIONS_CONFIG_INPUT_CLASS])!{},
                definitions
            )
        ) +
        attributeIfContent(
            STATE_CONFIG_INPUT_CLASS,
            combineEntities(
                (moduleInputState[STATE_CONFIG_INPUT_CLASS])![],
                stackOutputs,
                APPEND_COMBINE_BEHAVIOUR
            )
        )
    ]
[/#macro]

[#ftl]

[#-- modules allow loading input data using the engine itself --]
[#assign moduleConfiguration = {}]

[#function getActiveModulesFromLayers layersState ]

    [#local modules = [] ]

    [#local possibleModules = asFlattenedArray(getActiveLayerAttributes( [ "Modules" ], ["*"], [], layersState )) ]

    [#list possibleModules as moduleInstance ]
        [#list moduleInstance?values as module ]
            [#if (module.Enabled)!false]
                [#local modules += [ module ] ]
            [/#if]
        [/#list]
    [/#list]
    [#return modules ]
[/#function]

[#-- Adds module configuration definition which we use to validate modules loaded via blueprint --]
[#macro addModule name description provider properties=[] ]
    [@internalMergeModuleConfiguration
        name=name
        provider=provider
        configuration=
            {
                "Description" : description,
                "Properties" : asArray( [ "InhibitEnabled" ] + properties)
            }
    /]
[/#macro]

[#function getModuleDetails name provider parameters ]
    [#local moduleConfig = (moduleConfiguration[name][provider])!{} ]

    [#if ! moduleConfig?has_content ]
        [#return {}]
    [/#if]

    [#local validatedParameters = getCompositeObject(moduleConfig.Properties, parameters)]
    [#return
        {
            "Name" : name,
            "Provider" : provider,
            "Parameters" : validatedParameters
        }
    ]
[/#function]

[#-- Loads the module data into the input data --]

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
        attributeIfContent(COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS, commandLineOption) +
        attributeIfContent(BLUEPRINT_CONFIG_INPUT_CLASS, blueprint) +
        attributeIfContent(SETTINGS_CONFIG_INPUT_CLASS, formattedModuleSettings) +
        attributeIfContent(DEFINITIONS_CONFIG_INPUT_CLASS, definitions) +
        attributeIfContent(STATE_CONFIG_INPUT_CLASS, stackOutputs)
    ]
[/#macro]

[#-- Helper macro - not for general use --]
[#macro internalMergeModuleConfiguration name provider configuration]
    [#assign moduleConfiguration =
        mergeObjects(
            moduleConfiguration,
            {
                name : {
                    provider : configuration
                }
            }
        ) ]
[/#macro]

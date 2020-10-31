[#ftl]

[#-- modules allow loading input data using the engine itself --]
[#assign moduleConfiguration = {}]

[#function getActiveModulesFromLayers  ]

    [#local modules = [] ]

    [#local possibleModules = asFlattenedArray(getActiveLayerAttributes( [ "Modules" ] )) ]

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
]

    [#if blueprint?has_content ]
        [@addBlueprint
            blueprint=blueprint
        /]
    [/#if]

    [#list settingSets as settingSet ]
        [@addSettings
            type=settingSet.Type!"Settings"
            scope=settingSet.Scope!"Products"
            namespace=settingSet.Namespace
            settings=settingSet.Settings!{}
        /]
    [/#list]

    [@addStackOutputs
        outputs=stackOutputs
    /]

    [#if commandLineOption?has_content ]
        [@addCommandLineOption options=commandLineOption /]
    [/#if]
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

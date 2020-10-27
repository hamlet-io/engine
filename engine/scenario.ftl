[#ftl]

[#-- Scenarios allow loading input data using the engine itself --]
[#assign scenarioConfiguration = {}]

[#function getScenariosFromProfiles  ]
    [#-- We need to reload the scenario profiles whenever we call this function --]
    [#-- Another scenario may have modified the blueprintObject --]
    [@addReferenceData type=SCENARIOPROFILE_REFERENCE_TYPE base=blueprintObject /]
    [#local scenarioProfiles = getReferenceData(SCENARIOPROFILE_REFERENCE_TYPE) ]

    [#local scenarios = {} ]
    [#local profileNames =
        getUniqueArrayElements(
            (blueprintObject.Tenant.Profiles.Scenarios)![],
            (blueprintObject.Account.Profiles.Scenarios)![],
            (blueprintObject.Product.Profiles.Scenarios)![],
            (blueprintObject.Environment.Profiles.Scenarios)![],
            (blueprintObject.Segment.Profiles.Scenarios)![],
            (blueprintObject.Solution.Profiles.Scenarios)![]
        ) ]

    [#list profileNames as profileName ]
        [#local profileScenario = (scenarioProfiles[profileName])!{} ]

        [#list profileScenario.Scenarios as id, scenario ]
            [#if (scenario.Enabled)!false]
                [#local scenarios = mergeObjects( scenarios, { id : scenario } )]
            [/#if]
        [/#list]
    [/#list]
    [#return scenarios ]
[/#function]

[#-- Adds scenario configuration definition which we use to validate scenarios loaded via blueprint --]
[#macro addScenario name description provider properties=[] ]
    [@internalMergeScenarioConfiguration
        name=name
        provider=provider
        configuration=
            {
                "Description" : description,
                "Properties" : asArray( [ "InhibitEnabled" ] + properties)
            }
    /]
[/#macro]

[#function getScenarioDetails name provider parameters ]
    [#local scenarioConfig = (scenarioConfiguration[name][provider])!{} ]

    [#if ! scenarioConfig?has_content ]
        [#return {}]
    [/#if]

    [#local validatedParameters = getCompositeObject(scenarioConfig.Properties, parameters)]
    [#return
        {
            "Name" : name,
            "Provider" : provider,
            "Parameters" : validatedParameters
        }
    ]
[/#function]

[#-- Loads the scenario data into the input data --]
[#macro loadScenario
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
[#macro internalMergeScenarioConfiguration name provider configuration]
    [#assign scenarioConfiguration =
        mergeObjects(
            scenarioConfiguration,
            {
                name : {
                    provider : configuration
                }
            }
        ) ]
[/#macro]

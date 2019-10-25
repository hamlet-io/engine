[#ftl]

[#-- Scenarios allow loading input data using the engine itself --]
[#assign scenarioList = []]

[#macro updateScenarioList scenarioIds ]
    [#assign scenarioList = combineEntities( scenarioList, asArray(scenarioIds), UNIQUE_COMBINE_BEHAVIOUR )]
[/#macro]

[#macro addScenario
    id
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
            namespace=settingSet.Namespace!id
            settings=settingSet.Settings!{}
        /]
    [/#list]

    [#list stackOutputs as stackOutput ]
        [@addStackOutputs 
            [
                {
                    "DeploymentUnit" : id!deploymentUnit
                } +
                stackOutput
            ]
        /]
    [/#list]

    [#if commandLineOption?has_content ]
        [@addCommandLineOption options=commandLineOption /]
    [/#if]
[/#macro]

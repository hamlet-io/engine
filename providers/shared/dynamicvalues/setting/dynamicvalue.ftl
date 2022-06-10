[#ftl]

[@addDynamicValueProvider
    type=SETTING_DYNAMIC_VALUE_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Returns the value of a components setting"
        }
    ]
    parameterOrder=["settingEnvKey"]
    parameterAttributes=[
        {
            "Names" : "settingEnvKey",
            "Description" : "The Key of the setting when defined as an environment variable",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
    supportedComponentTypes=["*"]
/]

[#function shared_dynamicvalue_setting value properties occurrence extraSources={} ]
    [#local collectedSettings = {}]
    [#list (occurrence.Configuration.Settings)?values?filter(x -> x?has_content) as settingGroup ]
        [#list settingGroup as key, value]
            [#local collectedSettings = mergeObjects(collectedSettings, { key : value } )]
        [/#list]
    [/#list]

    [#return (collectedSettings[properties.settingEnvKey].Value)!""]
[/#function]

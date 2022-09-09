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
/]

[#function shared_dynamicvalue_setting value properties sources={} ]
    [#if sources.occurrence??]
        [#local collectedEnvironment = {}]
        [#list (sources.occurrence.Configuration.Environment)?values?filter(x -> x?has_content) as environmentGroup ]
            [#list environmentGroup as key, value]
                [#local collectedEnvironment = mergeObjects(collectedEnvironment, { key : value } )]
            [/#list]
        [/#list]

        [#return (collectedEnvironment[properties.settingEnvKey])!"__HamletFatal: dynamic setting value ${properties.settingEnvKey} not found__"]
    [/#if]
[/#function]

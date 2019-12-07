[#ftl]

[#-------------------------------------------
-- Public functions for setting processing --
---------------------------------------------]

[#assign settingsObject = {} ]

[#macro addSettings type scope namespace="" settings={} ]
    [@internalMergeSettings
        type=type
        scope=scope
        namespace=namespace
        settings=settings
    /]
[/#macro]

[#function formatSettingName parts...]
    [#-- First join the parts and force to upper case --]
    [#local name = concatenate(parts, "_")?upper_case ]

    [#-- Use a lookbehind regex to permit any non-alphanumeric to be escaped by "^" --]
    [#-- Double backslash is one for freemarker and one for regex --]
    [#local name = name?replace("(?<!\\^)[^0-9A-Z\\^]", "_", "r")]

    [#-- Finally remove ^ --]
    [#return name?replace("^", "")]
[/#function]

[#function asFlattenedSettings object prefix=""]
    [#local result = {} ]
    [#list object as key,value]
        [#if value?is_hash]
            [#if value.Value??]
                [#local result += {formatSettingName(prefix,key) : value} ]
            [#else]
                [#local result += asFlattenedSettings(value, formatSettingName(prefix, key)) ]
            [/#if]
            [#continue]
        [/#if]
        [#if value?is_sequence]
            [#continue]
        [/#if]
        [#local result += {formatSettingName(prefix, key) : {"Value" : value}} ]
    [/#list]
    [#return result]
[/#function]

[#function markAsSensitiveSettings settings]
    [#local result = {} ]
    [#list settings as key,value]
        [#local result += { key : value + {"Sensitive" : true}} ]
    [/#list]
    [#return result ]
[/#function]

[#-- Try to match the desired setting in decreasing specificity --]
[#-- A single match array or an array of arrays can be provided --]
[#-- Sets of settings are provide in least to most specific     --]
[#function getFirstSetting settingSets names emptyIfNotProvided=false]
    [#local nameAlternatives = asArray(names) ]
    [#if !(nameAlternatives[0]?is_sequence) ]
      [#local nameAlternatives = [nameAlternatives] ]
    [/#if]
    [#local settingNames = [] ]
    [#local setting = {} ]

    [#list nameAlternatives as nameAlternative]
        [#local nameParts = asArray(nameAlternative) ]
        [#list nameParts as namePart]
            [#local settingNames +=
                [formatSettingName(nameParts[namePart?index..])] ]
        [/#list]
    [/#list]

    [#list settingNames as settingName]
        [#list asArray(settingSets)?reverse as settingSet]

            [#local setting = settingSet[settingName]!{} ]
            [#if setting?has_content]
                [#break]
            [/#if]
        [/#list]
        [#if setting?has_content]
            [#break]
        [/#if]
    [/#list]

    [#return
        contentIfContent(
            setting,
            valueIfTrue(
                {"Value" : ""},
                emptyIfNotProvided,
                {"Value" : "COTFatal: Setting not provided"}
            )
        ) ]
[/#function]

[#function getSettingsAsEnvironment settings format={} ]

    [#local formatting =
        {
            "Include" : {
                "General" : true,
                "Sensitive" : true
            },
            "Obfuscate" : false,
            "Escaped" : true,
            "Prefix" : ""
        }  +
        format ]

    [#local result = {} ]

    [#list settings as key,value]
        [#if value?is_hash]
            [#if value.Internal!false]
                [#continue]
            [/#if]
            [#local serialisedValue =
                valueIfTrue(
                    valueIfTrue(
                        formatting.Prefix?ensure_ends_with(":"),
                        formatting.Prefix?has_content &&
                            (value.Value?is_hash || value.Value?is_sequence),
                        ""
                    ) +
                    asSerialisableString(value.Value),
                    formatting.Escaped,
                    value.Value) ]
            [#if ((formatting.Include.General)!true) && !(value.Sensitive!false)]
                [#local result += { key : serialisedValue} ]
                [#continue]
            [/#if]
            [#if ((formatting.Include.Sensitive)!true) && value.Sensitive!false]
                [#local result += { key : valueIfTrue("****", formatting.Obfuscate, serialisedValue)} ]
                [#continue]
            [/#if]
        [#else]
            [#local result += { key, "COTFatal:Internal error - setting is not a hash" } ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function getAsFileSettings settings ]
    [#local result = [] ]
    [#list settings as key,value]
        [#if value?is_hash && value.AsFile?has_content]
                [#local result += [value] ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#-----------------------------------------------------
-- Internal support functions for setting processing --
-------------------------------------------------------]

[#macro internalMergeSettings type scope namespace="" settings={} ]
    [#local types=[ "Settings", "Builds", "Sensitive" ]]
    [#local scopes=[ "Accounts", "Products" ]]

    [#if settings?has_content ]
        [#if ! types?seq_contains(type) && ! scopes?seq_contains(scope)  ]
            [@fatal
                message="Invalid Settings"
                context={ "Type" : type, "Scope" : scope, "Namespace" : namespace }
                detail={
                    "PossibleTypes" : types,
                    "PossibleScopes" : scopes
                }
            /]
        [/#if]

        [#if namespace?has_content ]
            [#assign settingsObject =
                mergeObjects(
                    settingsObject,
                    {
                        type : {
                            scope : {
                                namespace : settings
                            }
                        }
                    }
                )]
        [#else]
            [#assign settingsObject =
                mergeObjects(
                    settingsObject,
                    {
                        type : {
                            scope : settings
                        }
                    }
                )
            ]
        [/#if]
    [/#if]
[/#macro]

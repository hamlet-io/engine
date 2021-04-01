[#ftl]

[#-------------------------------------------
-- Public functions for setting processing --
---------------------------------------------]

[#function formatSettingsEntry type scope settings={} namespace="" ]
    [#return internalFormatSettingsEntry(type, scope, settings, namespace) ]
[/#function]

[#-- Normalise setting data --]
[#function normaliseCompositeSettings compositeSettings]
    [#return
        mergeObjects(
            internalFormatSettingsEntry(
                "Settings",
                "Accounts"
                internalReformatSettings(
                    (compositeSettings.Accounts.Settings)!{}
                )
            ),
            internalFormatSettingsEntry(
                "Settings",
                "Products",
                mergeObjects(
                    internalReformatSettings(
                        (compositeSettings.Products.Settings)!{},
                        r"^(?!.*build\.json|.*credentials\.json|.*sensitive\.json$).*$"
                    ),
                    internalReformatSettings(
                        (compositeSettings.Products.Operations)!{},
                        r"^(?!.*build\.json|.*credentials\.json|.*sensitive\.json$).*$"
                    )
                )
            ),
            internalFormatSettingsEntry(
                "Builds",
                "Products"
                mergeObjects(
                    internalReformatSettings(
                        (compositeSettings.Products.Settings)!{},
                        r"^.*build\.json$"
                    ),
                    internalReformatSettings(
                        (compositeSettings.Products.Builds)!{},
                        r"^.*build\.json$"
                    )
                )
            ),
            internalFormatSettingsEntry(
                "Sensitive",
                "Products"
                mergeObjects(
                    internalReformatSettings(
                        (compositeSettings.Products.Settings)!{},
                        r"^.*credentials\.json|.*sensitive\.json$"
                    ),
                    internalReformatSettings(
                        (compositeSettings.Products.Operations)!{},
                        r"^.*credentials\.json|.*sensitive\.json$"
                    )
                )
            )
        )
    ]
[/#function]

[#function formatSettingName upperCase parts...]
    [#-- First join the parts and force to upper case --]

    [#local name = concatenate(parts, "_") ]

    [#if upperCase ]
        [#local name = name?upper_case]
    [/#if]

    [#-- Use a lookbehind regex to permit any non-alphanumeric to be escaped by "^" --]
    [#-- Double backslash is one for freemarker and one for regex --]
    [#local name = name?replace("(?<!\\^)[^0-9A-Za-z\\^]", "_", "r")]

    [#-- Finally remove ^ --]
    [#return name?replace("^", "")]
[/#function]

[#function asFlattenedSettings object prefix=""]
    [#local result = {} ]
    [#list object as key,value]
        [#if value?is_hash]
            [#if value.Value??]
                [#local result += {formatSettingName(true, prefix,key) : value} ]
            [#else]
                [#local result += asFlattenedSettings(value, formatSettingName(true, prefix, key)) ]
            [/#if]
            [#continue]
        [/#if]
        [#if value?is_sequence]
            [#local result += {formatSettingName(true, prefix, key) : {"Value" : value, "Internal" : true}} ]
            [#continue]
        [/#if]
        [#local result += {formatSettingName(true, prefix, key) : {"Value" : value}} ]
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
                [formatSettingName(true, nameParts[namePart?index..])] ]
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
                {"Value" : "HamletFatal: Setting not provided"}
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
            [#local result += { key, "HamletFatal:Internal error - setting is not a hash" } ]
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

[#function internalFormatSettingsEntry type scope settings={} namespace="" ]
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
            [#return
                {
                    type : {
                        scope : {
                            namespace : settings
                        }
                    }
                }
            ]
        [#else]
            [#return
                {
                    type : {
                        scope : settings
                    }
                }
            ]
        [/#if]
    [/#if]
    [#return {} ]
[/#function]

[#function internalReformatSettings objects fileRegex=".*"]
    [#local result = {}]
    [#list objects!{} as key,value]
        [#local result =
            mergeObjects(
                result,
                internalReformatFiles(key, value!{}, fileRegex)
            )]
    [/#list]
    [#return result]
[/#function]

[#function internalReformatFiles key settingsFiles fileRegex]
    [#local result = {} ]
    [#list settingsFiles.Files![] as file ]
        [#-- Ignore the file if it doesn't match the desired regex --]
        [#if ! file.FileName?lower_case?trim?matches(fileRegex)]
            [#continue]
        [/#if]

        [#-- Locate files reative to the CMDB root --]
        [#local relativeFile =
            concatenate(
                [
                    file.FilePath?remove_beginning(settingsFiles.RootDirectory)?remove_beginning("/"),
                    file.FileName
                ],
                "/"
            ) ]

        [#-- The namespace starts with the key, followed by any parts of the file path --]
        [#-- relative to the base directory --]
        [#local extension = file.FileName?keep_after_last(".")]
        [#local base = file.FileName?remove_ending("." + extension)]
        [#local namespace =
            concatenate(
                [
                    key,
                    file.FilePath?remove_beginning(settingsFiles.BaseDirectory)?lower_case?replace("/", " ")?trim?split(" ")
                ],
                "-"
            ) ]

        [#-- Attribute for file contents --]
        [#local attribute = base?replace("-","_")?upper_case]

        [#-- asFile --]
        [#if file.FilePath?lower_case?contains("asfile")]
            [#local result =
                mergeObjects(
                    result,
                    {
                        namespace : {
                            attribute : {
                                "Value" : file.FileName,
                                "AsFile" : relativeFile
                            }
                        }
                    }
                 ) ]
            [#continue]
        [/#if]

        [#-- Settings format depends on file extension --]
        [#switch extension?lower_case]
            [#case "json"]
                [#local result =
                    mergeObjects(
                        result,
                        {
                            namespace : file.Content[0]
                        }
                     ) ]
                [#break]
            [#default]
                [#local result =
                    mergeObjects(
                        result,
                        {
                            namespace : {
                                attribute : {
                                    "Value" : file.Content[0],
                                    "FromFile" : relativeFile
                                }
                            }
                        }
                    ) ]
                [#break]
        [/#switch]
    [/#list]
    [#return result]
[/#function]


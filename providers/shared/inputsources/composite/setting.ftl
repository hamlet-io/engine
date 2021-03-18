[#ftl]

[#-- Initial seeding of settings data based on input data --]
[#macro shared_input_composite_setting_seed ]

    [#local compositeSettings = getCompositeSettings() ]

    [@addSettings
        type="Settings"
        scope="Accounts"
        settings=
            internalReformatSettings(
                (compositeSettings.Accounts.Settings)!{}
            )
    /]

    [#-- (?! ) negates the remaining expression --]
    [@addSettings
        type="Settings"
        scope="Products"
        settings=
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
    /]

    [@addSettings
        type="Builds"
        scope="Products"
        settings=
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
    /]

    [@addSettings
        type="Sensitive"
        scope="Products"
        settings=
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
    /]
[/#macro]

[#---------------------------------------------------------------
-- Internal support functions for composite setting processing --
-----------------------------------------------------------------]

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

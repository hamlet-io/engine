[#ftl]

[#-- Initial seeding of settings data based on input data --]
[#macro shared_input_whatif_setting_seed ]

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

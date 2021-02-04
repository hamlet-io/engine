[#ftl]

[#-- Initial seeding of settings data based on input data --]
[#macro shared_input_whatif_setting_seed ]
    [@addSettings
        type="Settings"
        scope="Accounts"
        settings=
            internalReformatSettings(
                (commandLineOptions.Composites.Settings.Accounts.Settings)!{}
            )
    /]

    [#-- (?! ) negates the remaining expression --]
    [@addSettings
        type="Settings"
        scope="Products"
        settings=
            mergeObjects(
                internalReformatSettings(
                    (commandLineOptions.Composites.Settings.Products.Settings)!{},
                    r"^(?!.*build\.json|.*credentials\.json|.*sensitive\.json$).*$"
                ),
                internalReformatSettings(
                    (commandLineOptions.Composites.Settings.Products.Operations)!{},
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
                    (commandLineOptions.Composites.Settings.Products.Settings)!{},
                    r"^.*build\.json$"
                ),
                internalReformatSettings(
                    (commandLineOptions.Composites.Settings.Products.Builds)!{},
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
                    (commandLineOptions.Composites.Settings.Products.Settings)!{},
                    r"^.*credentials\.json|.*sensitive\.json$"
                ),
                internalReformatSettings(
                    (commandLineOptions.Composites.Settings.Products.Operations)!{},
                    r"^.*credentials\.json|.*sensitive\.json$"
                )
            )
    /]
[/#macro]

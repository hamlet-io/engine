[#ftl]

[#-- Initial seeding of settings data based on input data --]
[#macro shared_input_composite_setting_seed ]
    [#-- Account settings --]
    [@addSettings
        type="Settings"
        scope="Accounts"
        settings=getCMDBAccountSettings().General
    /]

    [#-- Product settings --]
    [#local settings = getCMDBProductSettings() ]
    [@addSettings type="Settings"  scope="Products" settings=settings.General /]
    [@addSettings type="Builds"    scope="Products" settings=settings.Builds /]
    [@addSettings type="Sensitive" scope="Products" settings=settings.Sensitive /]

[/#macro]

[#---------------------------------------------------------------
-- Internal support functions for composite setting processing --
-----------------------------------------------------------------]

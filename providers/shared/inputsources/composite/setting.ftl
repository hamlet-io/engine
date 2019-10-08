[#ftl]

[#-- Get stack output --]
[#macro shared_input_composite_setting_default ]
    [@addSettings 
        type="Settings" 
        scope="Accounts" 
        settings=(commandLineOptions.Composites.Settings.Settings.Accounts)!{}
    /]

    [@addSettings 
        type="Settings" 
        scope="Products" 
        settings=(commandLineOptions.Composites.Settings.Settings.Products)!{}
    /]

    [@addSettings 
        type="Builds" 
        scope="Products" 
        settings=(commandLineOptions.Composites.Settings.Builds.Products)!{}
    /]

    [@addSettings
        type="Sensitive"
        scope="Products"
        settings=(commandLineOptions.Composites.Settings.Sensitve.Products)!{}
    /]
[/#macro]

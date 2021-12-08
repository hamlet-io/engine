[#ftl]

[#macro shared_view_default_configuration_generationcontract  ]
    [@addDefaultGenerationContract subsets=[ "config" ] /]
[/#macro]

[#macro shared_view_default_configuration ]
    [@addToDefaultJsonOutput
        content=getConfigurationScopes()
    /]
[/#macro]

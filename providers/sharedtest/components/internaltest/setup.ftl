[#ftl]

[#macro sharedtest_internaltest_default_deployment_generationcontract occurrence ]
    [@addDefaultGenerationContract subsets=[ "config" ] /]
[/#macro]


[#macro sharedtest_internaltest_default_deployment_config occurrence ]
    [@addToDefaultJsonOutput
        content={ "Occurrence" : occurrence }
    /]
[/#macro]

[#ftl]

[#macro shared_externalservice_default_deployment_generationcontract occurrence ]
    [@addDefaultGenerationContract subsets=[ "config" ] /]
[/#macro]

[#macro shared_externalservice_default_deployment_config occurrence ]
    [@addToDefaultJsonOutput
        content={ "Occurrence" : occurrence }
    /]
[/#macro]

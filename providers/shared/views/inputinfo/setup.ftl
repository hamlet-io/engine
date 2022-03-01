[#ftl]

[#macro shared_view_default_inputinfo_generationcontract  ]
    [@addDefaultGenerationContract subsets=[ "config" ] /]
[/#macro]

[#macro shared_view_default_inputinfo ]
    [@addToDefaultJsonOutput
        content={
            "InputSources" : getInputSources(),
            "InputStages" : getInputStages(),
            "InputSeeders": getInputSeeders(),
            "InputTransformers" : getInputTransformers()
        }
    /]
[/#macro]

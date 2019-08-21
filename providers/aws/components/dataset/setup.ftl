[#ftl]
[#macro aws_dataset_cf_application occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets=[ "prologue" ] /]
        [#return]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [@addToDefaultBashScriptOutput
            [
                "info \"Dataset deployment. Nothing to Do...\""
            ]
        /]
    [/#if]
[/#macro]

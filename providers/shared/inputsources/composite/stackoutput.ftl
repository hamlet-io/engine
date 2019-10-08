[#ftl]

[#-- Get stack output --]
[#macro shared_input_composite_stackoutput id="" deploymentUnit="" level="" region="" account=""]
    [#if ! stackOutputsList?has_content ]
        [@addStackOutputs commandLineOptions.Composites.StackOutputs /]
    [/#if]
[/#macro]

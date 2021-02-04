[#ftl]

[#macro shared_input_composite_stackoutput_seed id="" deploymentUnit="" level="" region="" account=""]
    [@addStackOutputs getCFCompositeStackOutputs(id, deploymentUnit, level, region, account) /]
[/#macro]
